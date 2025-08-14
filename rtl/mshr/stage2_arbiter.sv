module stage2_arbiter 
    import vector_cache_pkg::*; allow_w_rd_vld
    #(
    parameter integer unsigned  CHANNEL_SHIFT_REG_WIDTH = 10,
    parameter integer unsigned  RAM_SHIFT_REG_WIDTH     = 20
    ) (
    input  logic                    clk                     ,
    input  logic                    rst_n                   ,

    // read command in
    input  logic                    dataram_rd_in_vld_w         ,
    input  logic                    dataram_rd_in_vld_e         ,
    input  logic                    dataram_rd_in_vld_s         ,
    input  logic                    dataram_rd_in_vld_n         ,
    input  logic                    dataram_rd_in_vld_ev        ,

    input  arb_out_req_t            dataram_rd_in_pld_w         ,
    input  arb_out_req_t            dataram_rd_in_pld_e         ,
    input  arb_out_req_t            dataram_rd_in_pld_s         ,
    input  arb_out_req_t            dataram_rd_in_pld_n         ,
    input  arb_out_req_t            dataram_rd_in_pld_ev        ,

    output logic                    dataram_rd_in_rdy_w         ,
    output logic                    dataram_rd_in_rdy_e         ,
    output logic                    dataram_rd_in_rdy_s         ,
    output logic                    dataram_rd_in_rdy_n         ,
    output logic                    dataram_rd_in_rdy_ev        ,

    // write command in
    input  logic                    dataram_wr_in_vld_w         ,
    input  logic                    dataram_wr_in_vld_e         ,
    input  logic                    dataram_wr_in_vld_s         ,
    input  logic                    dataram_wr_in_vld_n         ,
    input  logic                    dataram_wr_in_vld_lf        ,

    input  arb_out_req_t            dataram_wr_in_pld_w         ,
    input  arb_out_req_t            dataram_wr_in_pld_e         ,
    input  arb_out_req_t            dataram_wr_in_pld_s         ,
    input  arb_out_req_t            dataram_wr_in_pld_n         ,
    input  arb_out_req_t            dataram_wr_in_pld_lf        ,
    
    output logic                    dataram_wr_in_rdy_w         ,
    output logic                    dataram_wr_in_rdy_e         ,
    output logic                    dataram_wr_in_rdy_s         ,
    output logic                    dataram_wr_in_rdy_n         ,    
    output logic                    dataram_wr_in_rdy_lf        ,

    // read command out
    output logic                    dataram_rd_out_vld_w        ,
    output logic                    dataram_rd_out_vld_e        ,
    output logic                    dataram_rd_out_vld_s        ,
    output logic                    dataram_rd_out_vld_n        ,
    output logic                    dataram_rd_out_vld_ev       ,

    output arb_out_req_t            dataram_rd_out_pld_w        ,
    output arb_out_req_t            dataram_rd_out_pld_e        ,
    output arb_out_req_t            dataram_rd_out_pld_s        ,
    output arb_out_req_t            dataram_rd_out_pld_n        ,
    output arb_out_req_t            dataram_rd_out_pld_ev       ,

    //write command out
    output logic                    dataram_wr_out_vld_w        ,
    output logic                    dataram_wr_out_vld_e        ,
    output logic                    dataram_wr_out_vld_s        ,
    output logic                    dataram_wr_out_vld_n        ,
    output logic                    dataram_wr_out_vld_lf       ,  

    output arb_out_req_t            dataram_wr_out_pld_w        ,
    output arb_out_req_t            dataram_wr_out_pld_e        ,
    output arb_out_req_t            dataram_wr_out_pld_s        ,
    output arb_out_req_t            dataram_wr_out_pld_n        ,
    output arb_out_req_t            dataram_wr_out_pld_lf 
);


    localparam integer unsigned     RD_BLOCK0_DELAY = 1;
    localparam integer unsigned     RD_BLOCK1_DELAY = 2;
    localparam integer unsigned     RD_BLOCK2_DELAY = 3;
    localparam integer unsigned     RD_BLOCK3_DELAY = 4; 
    localparam integer unsigned     WR_BLOCK0_DELAY = 8;
    localparam integer unsigned     WR_BLOCK1_DELAY = 7;
    localparam integer unsigned     WR_BLOCK2_DELAY = 6;
    localparam integer unsigned     WR_BLOCK3_DELAY = 5; 

    logic dataram_rd_in_vld_permitted_w     ;
    logic dataram_rd_in_vld_permitted_e     ;
    logic dataram_rd_in_vld_permitted_s     ;
    logic dataram_rd_in_vld_permitted_n     ;
    logic dataram_rd_in_vld_permitted_ev    ;

    logic dataram_wr_in_vld_permitted_w     ;
    logic dataram_wr_in_vld_permitted_e     ;
    logic dataram_wr_in_vld_permitted_s     ;
    logic dataram_wr_in_vld_permitted_n     ;
    logic dataram_wr_in_vld_permitted_lf    ;




    assign dataram_rd_out_pld_w     = dataram_rd_in_pld_w;
    assign dataram_rd_out_pld_e     = dataram_rd_in_pld_e;
    assign dataram_rd_out_pld_s     = dataram_rd_in_pld_s;
    assign dataram_rd_out_pld_n     = dataram_rd_in_pld_n;
    assign dataram_rd_out_pld_ev    = dataram_rd_in_pld_ev    ;

    assign dataram_wr_out_pld_w     = dataram_wr_in_pld_w;
    assign dataram_wr_out_pld_e     = dataram_wr_in_pld_e;
    assign dataram_wr_out_pld_s     = dataram_wr_in_pld_s;
    assign dataram_wr_out_pld_n     = dataram_wr_in_pld_n;
    assign dataram_wr_out_pld_lf    = dataram_wr_in_pld_lf;


    // request will be stalled when the channel or ram is not ready
    // each request will look up permission by channel_id and ram_id in payload.
    //     request_post_stalled           = original_valid       && sram permission                                                  && channel_permission 
    assign dataram_rd_in_vld_permitted_w  = dataram_rd_in_vld_w  && (ram_read_permission[dataram_rd_in_pld_w.dest_ram_id[2:1]])      && (channel_read_permission[dataram_rd_in_pld_w.dest_ram_id[0]]);
    assign dataram_rd_in_vld_permitted_e  = dataram_rd_in_vld_e  && (ram_read_permission[dataram_rd_in_pld_e.dest_ram_id[2:1]])      && (channel_read_permission[dataram_rd_in_pld_e.dest_ram_id[0]]);
    assign dataram_rd_in_vld_permitted_s  = dataram_rd_in_vld_s  && (ram_read_permission[dataram_rd_in_pld_s.dest_ram_id[2:1]])      && (channel_read_permission[dataram_rd_in_pld_s.dest_ram_id[0]]);
    assign dataram_rd_in_vld_permitted_n  = dataram_rd_in_vld_n  && (ram_read_permission[dataram_rd_in_pld_n.dest_ram_id[2:1]])      && (channel_read_permission[dataram_rd_in_pld_n.dest_ram_id[0]]);
    assign dataram_rd_in_vld_permitted_ev = dataram_rd_in_vld_ev && (ram_read_permission[dataram_rd_in_pld_ev.dest_ram_id[2:1]])     && (channel_read_permission[dataram_rd_in_pld_ev.dest_ram_id[0]]);

    assign dataram_wr_in_vld_permitted_w  = dataram_wr_in_vld_w  && (ram_write_permission_w[dataram_wr_in_pld_w.dest_ram_id[2:1]])   && (channel_write_permission_w[dataram_wr_in_pld_w.dest_ram_id[0]]);
    assign dataram_wr_in_vld_permitted_e  = dataram_wr_in_vld_e  && (ram_write_permission_e[dataram_wr_in_pld_e.dest_ram_id[2:1]])   && (channel_write_permission_e[dataram_wr_in_pld_e.dest_ram_id[0]]);
    assign dataram_wr_in_vld_permitted_s  = dataram_wr_in_vld_s  && (ram_write_permission_s[dataram_wr_in_pld_s.dest_ram_id[2:1]])   && (channel_write_permission_s[dataram_wr_in_pld_s.dest_ram_id[0]]);
    assign dataram_wr_in_vld_permitted_n  = dataram_wr_in_vld_n  && (ram_write_permission_n[dataram_wr_in_pld_n.dest_ram_id[2:1]])   && (channel_write_permission_n[dataram_wr_in_pld_n.dest_ram_id[0]]);
    assign dataram_wr_in_vld_permitted_lf = dataram_wr_in_vld_lf && (ram_write_permission_lf[dataram_wr_in_pld_lf.dest_ram_id[2:1]]) && (channel_write_permission_lf[dataram_wr_in_pld_lf.dest_ram_id[0]]);



    vr_2grant_arb u_vr_2grant_arb ( 
        .dataram_rd_in_vld_w        (dataram_rd_in_vld_permitted_w      ),
        .dataram_rd_in_vld_e        (dataram_rd_in_vld_permitted_e      ),
        .dataram_rd_in_vld_s        (dataram_rd_in_vld_permitted_s      ),
        .dataram_rd_in_vld_n        (dataram_rd_in_vld_permitted_n      ),
        .dataram_rd_in_vld_ev       (dataram_rd_in_vld_permitted_ev     ),

        .dataram_rd_in_rdy_w        (dataram_rd_in_rdy_w                ),
        .dataram_rd_in_rdy_e        (dataram_rd_in_rdy_e                ),
        .dataram_rd_in_rdy_s        (dataram_rd_in_rdy_s                ),
        .dataram_rd_in_rdy_n        (dataram_rd_in_rdy_n                ),
        .dataram_rd_in_rdy_ev       (dataram_rd_in_rdy_ev               ),
        
        .dataram_wr_in_vld_w        (dataram_wr_in_vld_permitted_w      ),
        .dataram_wr_in_vld_e        (dataram_wr_in_vld_permitted_e      ),
        .dataram_wr_in_vld_s        (dataram_wr_in_vld_permitted_s      ),
        .dataram_wr_in_vld_n        (dataram_wr_in_vld_permitted_n      ),
        .dataram_wr_in_vld_lf       (dataram_wr_in_vld_permitted_lf     ),
        
        .dataram_wr_in_rdy_w        (dataram_wr_in_rdy_w                ),
        .dataram_wr_in_rdy_e        (dataram_wr_in_rdy_e                ),
        .dataram_wr_in_rdy_s        (dataram_wr_in_rdy_s                ),
        .dataram_wr_in_rdy_n        (dataram_wr_in_rdy_n                ),
        .dataram_wr_in_rdy_lf       (dataram_wr_in_rdy_lf               ),
        
        .dataram_rd_out_vld_w       (dataram_rd_out_vld_w               ),
        .dataram_rd_out_vld_e       (dataram_rd_out_vld_e               ),
        .dataram_rd_out_vld_s       (dataram_rd_out_vld_s               ),
        .dataram_rd_out_vld_n       (dataram_rd_out_vld_n               ),
        .dataram_rd_out_vld_ev      (dataram_rd_out_vld_ev              ),
        
        .dataram_wr_out_vld_w       (dataram_wr_out_vld_w               ),
        .dataram_wr_out_vld_e       (dataram_wr_out_vld_e               ),
        .dataram_wr_out_vld_s       (dataram_wr_out_vld_s               ),
        .dataram_wr_out_vld_n       (dataram_wr_out_vld_n               ),
        .dataram_wr_out_vld_lf      (dataram_wr_out_vld_lf              ));








    generate for(genvar i=0;i<2;i=i+1) begin

        assign ch_sr_update_en_w    [i] = (dataram_wr_out_pld_w.dest_ram_id[0] == i) && dataram_wr_out_vld_w;
        assign ch_sr_update_en_e    [i] = (dataram_wr_out_pld_e.dest_ram_id[0] == i) && dataram_wr_out_vld_e;
        assign ch_sr_update_en_s    [i] = (dataram_wr_out_pld_s.dest_ram_id[0] == i) && dataram_wr_out_vld_s;
        assign ch_sr_update_en_n    [i] = (dataram_wr_out_pld_n.dest_ram_id[0] == i) && dataram_wr_out_vld_n;
        assign ch_sr_update_en_lf   [i] = (dataram_wr_out_pld_lf.dest_ram_id[0] == i) && dataram_wr_out_vld_lf;

        vcache_channel_shift_reg u_channel_sr (
            .clk                   (clk                         ),    
            .rst_n                 (rst_n                       ),

            .update_en_w           (ch_sr_update_en_w      [i]  ),
            .update_en_e           (ch_sr_update_en_e      [i]  ),
            .update_en_s           (ch_sr_update_en_s      [i]  ),
            .update_en_n           (ch_sr_update_en_n      [i]  ),
            .update_en_lf          (ch_sr_update_en_lf     [i]  ),

            .write_permission_w    (ch_write_permission_w  [i]  ),
            .write_permission_e    (ch_write_permission_e  [i]  ),
            .write_permission_s    (ch_write_permission_s  [i]  ),
            .write_permission_n    (ch_write_permission_n  [i]  ),
            .write_permission_lf   (ch_write_permission_lf [i]  ),

            .read_permission       (ch_read_permission     [i]  ));
    end endgenerate


    generate for(genvar j=0;j<4;j=j+1) begin

        assign ram_sr_update_en_w   [j] = (dataram_wr_out_pld_w.dest_ram_id[2:1] == j) && dataram_wr_out_vld_w     ;
        assign ram_sr_update_en_e   [j] = (dataram_wr_out_pld_e.dest_ram_id[2:1] == j) && dataram_wr_out_vld_e     ;
        assign ram_sr_update_en_s   [j] = (dataram_wr_out_pld_s.dest_ram_id[2:1] == j) && dataram_wr_out_vld_s     ;
        assign ram_sr_update_en_n   [j] = (dataram_wr_out_pld_n.dest_ram_id[2:1] == j) && dataram_wr_out_vld_n     ;
        assign ram_sr_update_en_lf  [j] = (dataram_wr_out_pld_lf.dest_ram_id[2:1] == j) && dataram_wr_out_vld_lf    ;


        vcache_ram_shift_reg u_ram_sr (
            .clk                    (clk                         ),    
            .rst_n                  (rst_n                       ),

            .update_en_w            (ram_sr_update_en_w      [j]  ),
            .update_en_e            (ram_sr_update_en_e      [j]  ),
            .update_en_s            (ram_sr_update_en_s      [j]  ),
            .update_en_n            (ram_sr_update_en_n      [j]  ),
            .update_en_lf           (ram_sr_update_en_lf     [j]  ),

            .write_permission_w     (ram_write_permission_w  [j]  ),
            .write_permission_e     (ram_write_permission_e  [j]  ),
            .write_permission_s     (ram_write_permission_s  [j]  ),
            .write_permission_n     (ram_write_permission_n  [j]  ),
            .write_permission_lf    (ram_write_permission_lf [j]  ),
    
            .read_permission        (ram_read_permission     [j]  ));
    end endgenerate


endmodule