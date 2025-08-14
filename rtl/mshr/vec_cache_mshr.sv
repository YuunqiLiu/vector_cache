module vec_cache_mshr 
    import vector_cache_pkg::*;
    (
    input  logic                                        clk                     ,
    input  logic                                        rst_n                   ,    

    input  logic                                        mshr_update_en_0        ,
    input  logic                                        mshr_update_en_1        ,
    input  mshr_entry_t                                 mshr_update_pld_0       ,
    input  mshr_entry_t                                 mshr_update_pld_1       ,

    output logic                                        alloc_vld_0             ,//to tag pipe
    output logic [MSHR_ENTRY_IDX_WIDTH-1:0]             alloc_idx_0             ,
    input  logic                                        alloc_rdy_0             ,
    output logic                                        alloc_vld_1             ,
    output logic [MSHR_ENTRY_IDX_WIDTH-1:0]             alloc_idx_1             ,
    input  logic                                        alloc_rdy_1             ,

    output logic                                        west_read_cmd_vld       ,
    output arb_out_req_t                                west_read_cmd_pld       ,
    output logic                                        east_read_cmd_vld       ,
    output arb_out_req_t                                east_read_cmd_pld       ,
    output logic                                        south_read_cmd_vld      ,
    output arb_out_req_t                                south_read_cmd_pld      ,
    output logic                                        north_read_cmd_vld      ,
    output arb_out_req_t                                north_read_cmd_pld      ,

    output logic                                        west_write_cmd_vld      ,
    output arb_out_req_t                                west_write_cmd_pld      ,
    output logic                                        east_write_cmd_vld      ,
    output arb_out_req_t                                east_write_cmd_pld      ,
    output logic                                        south_write_cmd_vld     ,
    output arb_out_req_t                                south_write_cmd_pld     ,
    output logic                                        north_write_cmd_vld     ,
    output arb_out_req_t                                north_write_cmd_pld     ,

    output arb_out_req_t                                evict_req_pld           ,
    output logic                                        evict_req_vld           ,
    input  logic                                        evict_req_rdy           ,
    output arb_out_req_t                                lf_wrreq_pld            ,//linefill write request
    output logic                                        lf_wrreq_vld            ,//linefill write request
    input  logic                                        lf_wrreq_rdy            ,

    input  logic                                        downstream_txreq_rdy    ,// to ds
    output logic                                        downstream_txreq_vld    ,
    output downstream_txreq_pld_t                       downstream_txreq_pld    ,

    input  logic                                        ds_txreq_done           ,//linefill ack
    input  logic [MSHR_ENTRY_IDX_WIDTH-1  :0]           ds_txreq_done_idx       ,
    input  logic [$clog2(LFDB_ENTRY_NUM/4)-1:0]         ds_txreq_done_db_id     ,
    input  logic                                        linefill_done           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1  :0]           linefill_done_idx       ,

    input  logic                                        west_rd_done            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             west_rd_done_idx        ,
    input  logic                                        east_rd_done            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             east_rd_done_idx        ,
    input  logic                                        south_rd_done           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             south_rd_done_idx       ,
    input  logic                                        north_rd_done           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             north_rd_done_idx       ,

    input  logic                                        west_wr_done            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             west_wr_done_idx        ,
    input  logic                                        east_wr_done            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             east_wr_done_idx        ,
    input  logic                                        south_wr_done           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             south_wr_done_idx       ,
    input  logic                                        north_wr_done           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             north_wr_done_idx       ,

    input  logic                                        evict_clean             ,//evict ack
    input  logic [MSHR_ENTRY_IDX_WIDTH-1  :0]           evict_clean_idx         ,
    input  logic                                        bresp_vld               ,//Bresp evict done
    input  bresp_pld_t                                  bresp_pld               ,//Bresp //txnid+sideband+rob_id
    output logic                                        bresp_rdy               ,//Bresp

    output hzd_mshr_pld_t                               v_mshr_entry_pld_out[MSHR_ENTRY_NUM-1:0],
    input  logic                                        w_rdb_alloc_nfull       ,
    input  logic                                        e_rdb_alloc_nfull       ,
    input  logic                                        s_rdb_alloc_nfull       ,
    input  logic                                        n_rdb_alloc_nfull       ,

    input  logic                                        linefill_alloc_vld      ,
    input  logic [$clog2(LFDB_ENTRY_NUM/4)-1:0]         linefill_alloc_idx      ,
    output logic                                        linefill_alloc_rdy  
    );

    logic  [MSHR_ENTRY_NUM-1         :0]                v_mshr_update_en_0                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_mshr_update_en_1                             ;    
    logic  [MSHR_ENTRY_NUM-1         :0]                v_alloc_vld                                    ; 
    logic  [MSHR_ENTRY_NUM-1         :0]                v_alloc_rdy                                    ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_w_dataram_rd_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_e_dataram_rd_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_s_dataram_rd_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_n_dataram_rd_vld                             ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_w_dataram_rd_rdy                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_e_dataram_rd_rdy                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_s_dataram_rd_rdy                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_n_dataram_rd_rdy                             ;
    arb_out_req_t                                       v_dataram_rd_pld   [MSHR_ENTRY_NUM-1:0]        ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_w_dataram_wr_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_e_dataram_wr_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_s_dataram_wr_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_n_dataram_wr_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_w_dataram_wr_rdy                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_e_dataram_wr_rdy                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_s_dataram_wr_rdy                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_n_dataram_wr_rdy                             ;
    arb_out_req_t                                       v_dataram_wr_pld    [MSHR_ENTRY_NUM-1:0]       ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_downstream_txreq_vld                         ;
    downstream_txreq_pld_t                              v_downstream_txreq_pld[MSHR_ENTRY_NUM-1:0]     ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_downstream_txreq_rdy                         ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_linefill_req_vld                             ;
    arb_out_req_t                                       v_linefill_req_pld  [MSHR_ENTRY_NUM-1 :0]      ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_linefill_req_rdy                             ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_evict_rd_vld                                 ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_evict_rd_rdy                                 ;
    arb_out_req_t                                       v_evict_rd_pld[MSHR_ENTRY_NUM-1:0]             ;
     
    logic [MSHR_ENTRY_NUM-1         :0]                 v_release_en                                   ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_linefill_done                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_ds_txreq_done                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_west_rd_done                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_east_rd_done                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_south_rd_done                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_north_rd_done                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_west_wr_done                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_east_wr_done                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_south_wr_done                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_north_wr_done                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_evict_done                                   ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_evict_clean                                  ;

    arb_out_req_t                                       linefill_req_pld                        ;
    logic                                               linefill_req_vld                        ;
    logic                                               linefill_req_rdy                        ;
    arb_out_req_t                                       evict_rd_pld                            ;
    logic                                               evict_rd_vld                            ;
    logic                                               evict_rd_rdy                            ;
    arb_out_req_t                                       w_dataram_wr_pld                        ;
    arb_out_req_t                                       e_dataram_wr_pld                        ;
    arb_out_req_t                                       s_dataram_wr_pld                        ;
    arb_out_req_t                                       n_dataram_wr_pld                        ;
    logic                                               w_dataram_wr_vld                        ;
    logic                                               e_dataram_wr_vld                        ;
    logic                                               s_dataram_wr_vld                        ;
    logic                                               n_dataram_wr_vld                        ;
    logic                                               w_dataram_wr_rdy                        ;
    logic                                               e_dataram_wr_rdy                        ;
    logic                                               s_dataram_wr_rdy                        ;
    logic                                               n_dataram_wr_rdy                        ;

    arb_out_req_t                                       w_dataram_rd_pld                        ;
    arb_out_req_t                                       e_dataram_rd_pld                        ;
    arb_out_req_t                                       s_dataram_rd_pld                        ;
    arb_out_req_t                                       n_dataram_rd_pld                        ;
    logic                                               w_dataram_rd_vld                        ;
    logic                                               e_dataram_rd_vld                        ;
    logic                                               s_dataram_rd_vld                        ;
    logic                                               n_dataram_rd_vld                        ;
    logic                                               w_dataram_rd_rdy                        ;
    logic                                               e_dataram_rd_rdy                        ;
    logic                                               s_dataram_rd_rdy                        ;
    logic                                               n_dataram_rd_rdy                        ;


    pre_alloc_two #(
        .ENTRY_NUM(MSHR_ENTRY_NUM    ),
        .ENTRY_ID_WIDTH($clog2(MSHR_ENTRY_NUM))
    ) u_pre_allocator (
        .clk        (clk          ),
        .rst_n      (rst_n        ),
        .v_in_vld   (v_alloc_vld  ),
        .v_in_rdy   (v_alloc_rdy  ),
        .out_vld_0  (alloc_vld_0  ),
        .out_vld_1  (alloc_vld_1  ),
        .out_rdy_0  (alloc_rdy_0  ),
        .out_rdy_1  (alloc_rdy_1  ),
        .out_idx_0  (alloc_idx_0  ),
        .out_idx_1  (alloc_idx_1  ));

// mshr entry enable decode
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_update_entry_dec0 (
        .enable         (mshr_update_en_0    ),
        .enable_index   (mshr_update_pld_0.alloc_idx),
        .v_out_en       (v_mshr_update_en_0));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_update_entry_dec1 (
        .enable         (mshr_update_en_1    ),
        .enable_index   (mshr_update_pld_1.alloc_idx),
        .v_out_en       (v_mshr_update_en_1));

    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_lf_data_dec (
        .enable         (ds_txreq_done    ),
        .enable_index   (ds_txreq_done_idx),
        .v_out_en       (v_ds_txreq_done  ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM   )
    )   u_linefill_done_dec (
        .enable         (linefill_done    ),
        .enable_index   (linefill_done_idx),
        .v_out_en       (v_linefill_done  ));
//--------read done decode----------------
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_west_rd_done_dec (
        .enable         (west_rd_done        ),
        .enable_index   (west_rd_done_idx    ),
        .v_out_en       (v_west_rd_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_east_rd_done_dec (
        .enable         (east_rd_done        ),
        .enable_index   (east_rd_done_idx    ),
        .v_out_en       (v_east_rd_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_south_rd_done_dec (
        .enable         (south_rd_done        ),
        .enable_index   (south_rd_done_idx    ),
        .v_out_en       (v_south_rd_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_north_rd_done_dec (
        .enable         (north_rd_done        ),
        .enable_index   (north_rd_done_idx    ),
        .v_out_en       (v_north_rd_done      ));
//------------------------------------------

//--------write_done decode--------------
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_west_wr_done_dec (
        .enable         (west_wr_done        ),
        .enable_index   (west_wr_done_idx    ),
        .v_out_en       (v_west_wr_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_east_wr_done_dec (
        .enable         (east_wr_done        ),
        .enable_index   (east_wr_done_idx    ),
        .v_out_en       (v_east_wr_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_south_wr_done_dec (
        .enable         (south_wr_done        ),
        .enable_index   (south_wr_done_idx    ),
        .v_out_en       (v_south_wr_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_north_wr_done_dec (
        .enable         (north_wr_done        ),
        .enable_index   (north_wr_done_idx    ),
        .v_out_en       (v_north_wr_done      ));
//-------------------------------------------------

    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_evict_done_dec (
        .enable         (bresp_vld      ),//evict_done
        .enable_index   (bresp_pld.rob_entry_id ),
        .v_out_en       (v_evict_done   ));

    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_evict_clean_dec (
        .enable         (evict_clean    ),
        .enable_index   (evict_clean_idx),
        .v_out_en       (v_evict_clean  ));

    //check state
    generate
        for (genvar i=0;i<MSHR_ENTRY_NUM;i=i+1)begin:MSHR_ENTRY_ARRAY
            vec_cache_mshr_entry  u_vec_cache_mshr_entry(
            .clk                    (clk                        ),
            .rst_n                  (rst_n                      ),
            .mshr_update_en_0       (v_mshr_update_en_0[i]      ),
            .mshr_update_en_1       (v_mshr_update_en_1[i]      ),
            .mshr_update_pld_0      (mshr_update_pld_0          ),
            .mshr_update_pld_1      (mshr_update_pld_1          ),
            .mshr_out_pld           (v_mshr_entry_pld_out[i]    ),
            .alloc_vld              (v_alloc_vld[i]             ),
            .alloc_rdy              (v_alloc_rdy[i]             ),

            .w_dataram_rd_rdy       (v_w_dataram_rd_rdy[i]      ),
            .e_dataram_rd_rdy       (v_e_dataram_rd_rdy[i]      ),
            .s_dataram_rd_rdy       (v_s_dataram_rd_rdy[i]      ),
            .n_dataram_rd_rdy       (v_n_dataram_rd_rdy[i]      ),
            .w_dataram_rd_vld       (v_w_dataram_rd_vld[i]      ),
            .e_dataram_rd_vld       (v_e_dataram_rd_vld[i]      ),
            .s_dataram_rd_vld       (v_s_dataram_rd_vld[i]      ),
            .n_dataram_rd_vld       (v_n_dataram_rd_vld[i]      ),
            .dataram_rd_pld         (v_dataram_rd_pld[i]        ),
            .w_dataram_wr_rdy       (v_w_dataram_wr_rdy[i]      ),
            .e_dataram_wr_rdy       (v_e_dataram_wr_rdy[i]      ),
            .s_dataram_wr_rdy       (v_s_dataram_wr_rdy[i]      ),
            .n_dataram_wr_rdy       (v_n_dataram_wr_rdy[i]      ),
            .w_dataram_wr_vld       (v_w_dataram_wr_vld[i]      ),
            .e_dataram_wr_vld       (v_e_dataram_wr_vld[i]      ),
            .s_dataram_wr_vld       (v_s_dataram_wr_vld[i]      ),
            .n_dataram_wr_vld       (v_n_dataram_wr_vld[i]      ),
            .dataram_wr_pld         (v_dataram_wr_pld[i]        ),
            .evict_rdy              (v_evict_rd_rdy[i]          ),
            .evict_rd_vld           (v_evict_rd_vld[i]          ),  
            .evict_rd_pld           (v_evict_rd_pld[i]          ),
            .downstream_txreq_vld   (v_downstream_txreq_vld[i]  ),
            .downstream_txreq_rdy   (v_downstream_txreq_rdy[i]  ),
            .downstream_txreq_pld   (v_downstream_txreq_pld[i]  ),
            .linefill_req_vld       (v_linefill_req_vld[i]      ),
            .linefill_req_pld       (v_linefill_req_pld[i]      ),
            .linefill_req_rdy       (v_linefill_req_rdy[i]      ),

            .ds_txreq_done          (v_ds_txreq_done[i]         ),
            .ds_txreq_done_db_id    (ds_txreq_done_db_id        ),
            .linefill_done          (v_linefill_done[i]         ),
            .west_rd_done           (v_west_rd_done[i]          ),
            .east_rd_done           (v_east_rd_done[i]          ),
            .south_rd_done          (v_south_rd_done[i]         ),
            .north_rd_done          (v_north_rd_done[i]         ),
            .west_wr_done           (v_west_wr_done[i]          ),
            .east_wr_done           (v_east_wr_done[i]          ),
            .south_wr_done          (v_south_wr_done[i]         ),
            .north_wr_done          (v_north_wr_done[i]         ),
            .evict_done             (v_evict_done[i]            ),
            .evict_clean            (v_evict_clean[i]           ),

            .linefill_alloc_vld     (linefill_alloc_vld         ),
            .linefill_alloc_idx     (linefill_alloc_idx         ),
            .w_rdb_alloc_nfull       (w_rdb_alloc_nfull         ),
            .e_rdb_alloc_nfull       (e_rdb_alloc_nfull         ),
            .s_rdb_alloc_nfull       (s_rdb_alloc_nfull         ),
            .n_rdb_alloc_nfull       (n_rdb_alloc_nfull         ),

            .v_release_en           (v_release_en               ),
            .release_en             (v_release_en[i]            ));
        end
    endgenerate

    //miss req to DS arb
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM ),
        .PLD_WIDTH ($bits(downstream_txreq_pld_t))
    ) u_downstream_req_arb (
        .v_vld_s(v_downstream_txreq_vld ),
        .v_rdy_s(v_downstream_txreq_rdy ),
        .v_pld_s(v_downstream_txreq_pld ),
        .vld_m  (downstream_txreq_vld   ),
        .rdy_m  (downstream_txreq_rdy   ),
        .pld_m  (downstream_txreq_pld   ));


//======================================================================
// stage one arbiter
//======================================================================    
//读arb----------------------------------------------------------------
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_w_dataram_rd_arb (
        .v_vld_s(v_w_dataram_rd_vld ),
        .v_rdy_s(v_w_dataram_rd_rdy ),
        .v_pld_s(v_dataram_rd_pld   ),
        .vld_m  (w_dataram_rd_vld   ),
        .rdy_m  (w_dataram_rd_rdy   ),
        .pld_m  (w_dataram_rd_pld   ));
    
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_e_dataram_rd_arb (
        .v_vld_s(v_e_dataram_rd_vld ),
        .v_rdy_s(v_e_dataram_rd_rdy ),
        .v_pld_s(v_dataram_rd_pld   ),
        .vld_m  (e_dataram_rd_vld   ),
        .rdy_m  (e_dataram_rd_rdy   ),
        .pld_m  (e_dataram_rd_pld   ));
        
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_s_dataram_rd_arb (
        .v_vld_s(v_s_dataram_rd_vld ),
        .v_rdy_s(v_s_dataram_rd_rdy ),
        .v_pld_s(v_dataram_rd_pld   ),
        .vld_m  (s_dataram_rd_vld   ),
        .rdy_m  (s_dataram_rd_rdy   ),
        .pld_m  (s_dataram_rd_pld   ));
        
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_n_dataram_rd_arb (
        .v_vld_s(v_n_dataram_rd_vld ),
        .v_rdy_s(v_n_dataram_rd_rdy ),
        .v_pld_s(v_dataram_rd_pld   ),
        .vld_m  (n_dataram_rd_vld   ),
        .rdy_m  (n_dataram_rd_rdy   ),
        .pld_m  (n_dataram_rd_pld   ));


//写arb----------------------------------------------------------------
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_w_dataram_wr_arb (
        .v_vld_s(v_w_dataram_wr_vld   ),
        .v_rdy_s(v_w_dataram_wr_rdy   ),
        .v_pld_s(v_dataram_wr_pld     ),
        .vld_m  (w_dataram_wr_vld     ),
        .rdy_m  (w_dataram_wr_rdy     ),
        .pld_m  (w_dataram_wr_pld    ));

    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_e_dataram_wr_arb (
        .v_vld_s(v_e_dataram_wr_vld   ),
        .v_rdy_s(v_e_dataram_wr_rdy   ),
        .v_pld_s(v_dataram_wr_pld     ),
        .vld_m  (e_dataram_wr_vld     ),
        .rdy_m  (e_dataram_wr_rdy     ),
        .pld_m  (e_dataram_wr_pld    ));

    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_s_dataram_wr_arb (
        .v_vld_s(v_s_dataram_wr_vld   ),
        .v_rdy_s(v_s_dataram_wr_rdy   ),
        .v_pld_s(v_dataram_wr_pld     ),
        .vld_m  (s_dataram_wr_vld     ),
        .rdy_m  (s_dataram_wr_rdy     ),
        .pld_m  (s_dataram_wr_pld    ));

    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_n_dataram_wr_arb (
        .v_vld_s(v_n_dataram_wr_vld   ),
        .v_rdy_s(v_n_dataram_wr_rdy   ),
        .v_pld_s(v_dataram_wr_pld     ),
        .vld_m  (n_dataram_wr_vld     ),
        .rdy_m  (n_dataram_wr_rdy     ),
        .pld_m  (n_dataram_wr_pld    ));


//evict read req arb----------------------------------------------------------------
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_dataram_evict_arb (
        .v_vld_s(v_evict_rd_vld   ),
        .v_rdy_s(v_evict_rd_rdy   ),
        .v_pld_s(v_evict_rd_pld   ),
        .vld_m  (evict_rd_vld     ),
        .rdy_m  (evict_rd_rdy     ),
        .pld_m  (evict_rd_pld     ));


//linefill req(write sram) arb--------------------------------------------
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_lfreq_arb (
        .v_vld_s(v_linefill_req_vld   ),
        .v_rdy_s(v_linefill_req_rdy   ),
        .v_pld_s(v_linefill_req_pld   ),
        .vld_m  (linefill_req_vld     ),
        .rdy_m  (linefill_req_rdy     ),
        .pld_m  (linefill_req_pld     ));

//======================================================================
// stage two arbiter
//====================================================================== 

    //assign grant_ram_rdy = dataram_rdy && lf_wrreq_rdy;
    stage2_arbiter # ( 
        .CHANNEL_SHIFT_REG_WIDTH(20),
        .RAM_SHIFT_REG_WIDTH    (20))
    u_stage2_arbiter ( 
        .clk                    (clk                ),
        .rst_n                  (rst_n              ),
        .w_dataram_rd_vld       (w_dataram_rd_vld   ),
        .e_dataram_rd_vld       (e_dataram_rd_vld   ),
        .s_dataram_rd_vld       (s_dataram_rd_vld   ),
        .n_dataram_rd_vld       (n_dataram_rd_vld   ),
        .evict_rd_vld           (evict_rd_vld       ),
        .w_dataram_rd_pld       (w_dataram_rd_pld   ),
        .e_dataram_rd_pld       (e_dataram_rd_pld   ),
        .s_dataram_rd_pld       (s_dataram_rd_pld   ),
        .n_dataram_rd_pld       (n_dataram_rd_pld   ),
        .evict_rd_pld           (evict_rd_pld       ),
        .w_dataram_rd_rdy       (w_dataram_rd_rdy   ),
        .e_dataram_rd_rdy       (e_dataram_rd_rdy   ),
        .s_dataram_rd_rdy       (s_dataram_rd_rdy   ),
        .n_dataram_rd_rdy       (n_dataram_rd_rdy   ),
        .evict_rd_rdy           (evict_rd_rdy       ),
        .w_dataram_wr_vld       (w_dataram_wr_vld   ),
        .e_dataram_wr_vld       (e_dataram_wr_vld   ),
        .s_dataram_wr_vld       (s_dataram_wr_vld   ),
        .n_dataram_wr_vld       (n_dataram_wr_vld   ),
        .linefill_req_vld       (linefill_req_vld   ),
        .w_dataram_wr_pld       (w_dataram_wr_pld   ),
        .e_dataram_wr_pld       (e_dataram_wr_pld   ),
        .s_dataram_wr_pld       (s_dataram_wr_pld   ),
        .n_dataram_wr_pld       (n_dataram_wr_pld   ),
        .linefill_req_pld       (linefill_req_pld   ),
        .w_dataram_wr_rdy       (w_dataram_wr_rdy   ),
        .e_dataram_wr_rdy       (e_dataram_wr_rdy   ),
        .s_dataram_wr_rdy       (s_dataram_wr_rdy   ),
        .n_dataram_wr_rdy       (n_dataram_wr_rdy   ),
        .linefill_req_rdy       (linefill_req_rdy   ),
        .arbout_w_dataram_rd_vld(west_read_cmd_vld  ),
        .arbout_e_dataram_rd_vld(east_read_cmd_vld  ),
        .arbout_s_dataram_rd_vld(south_read_cmd_vld ),
        .arbout_n_dataram_rd_vld(north_read_cmd_vld ),
        .arbout_evict_rd_vld    (evict_req_vld      ),
        .arbout_w_dataram_rd_pld(west_read_cmd_pld  ),
        .arbout_e_dataram_rd_pld(east_read_cmd_pld  ),
        .arbout_s_dataram_rd_pld(south_read_cmd_pld ),
        .arbout_n_dataram_rd_pld(north_read_cmd_pld ),
        .arbout_evict_rd_pld    (evict_req_pld      ),
        .arbout_w_dataram_wr_vld(west_write_cmd_vld ),
        .arbout_e_dataram_wr_vld(east_write_cmd_vld ),
        .arbout_s_dataram_wr_vld(south_write_cmd_vld),
        .arbout_n_dataram_wr_vld(north_write_cmd_vld),
        .arbout_linefill_req_vld(lf_wrreq_vld       ),
        .arbout_w_dataram_wr_pld(west_write_cmd_pld ),
        .arbout_e_dataram_wr_pld(east_write_cmd_pld ),
        .arbout_s_dataram_wr_pld(south_write_cmd_pld),
        .arbout_n_dataram_wr_pld(north_write_cmd_pld),
        .arbout_linefill_req_pld(lf_wrreq_pld       ));
    
endmodule

