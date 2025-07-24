module loop_back
    import vector_cache_pkg::*; 
    (
    input  logic                clk                                   ,
    input  logic                clk_div                               ,
    input  logic                rst_n                                 ,

    input  write_ram_cmd_t      west_write_cmd_pld_in        [7:0]    ,
    input  logic [7:0]          west_write_cmd_vld_in                 ,
    input  arb_out_req_t        west_read_cmd_pld_in         [7:0]    ,
    input  logic [7:0]          west_read_cmd_vld_in                  ,
    input  logic [7  :0]        west_data_in_vld                      ,
    input  group_data_pld_t     west_data_in                 [7  :0]  ,

    input  write_ram_cmd_t      east_write_cmd_pld_in        [7:0]    ,//east wdb
    input  logic [7:0]          east_write_cmd_vld_in                 ,//east wdb
    input  logic [7  :0]        east_data_in_vld                      ,
    input  group_data_pld_t     east_data_in                  [7  :0] ,

    output arb_out_req_t        west_read_cmd_pld_out         [7:0]   ,
    output logic [7:0]          west_read_cmd_vld_out                 ,
    output write_ram_cmd_t      west_write_cmd_pld_out        [7:0]   ,
    output logic [7:0]          west_write_cmd_vld_out                ,

    output logic [7  :0]        west_data_out_vld                     ,
    output group_data_pld_t     west_data_out                 [7  :0] ,

    output arb_out_req_t        east_read_cmd_pld_out         [7:0]   ,//tmp，不会输出
    output logic [7:0]          east_read_cmd_vld_out                 ,//tmp，不会输出
    output logic [7  :0]        east_data_out_vld                     ,
    output group_data_pld_t     east_data_out                 [7  :0] 

    );

    //rd east decode
    generate
        for(genvar i=0;i<8;i=i+1)begin
            assign west_read_cmd_vld_out[i] = (west_read_cmd_pld_in[i].txnid.direction_id == 2'd1) ? 1'b0 : west_read_cmd_vld_in[i];
            assign west_read_cmd_pld_out[i] = west_read_cmd_pld_in[i];
        end
    endgenerate

    generate
        for(genvar i=0;i<8;i=i+1)begin
            assign east_read_cmd_vld_out[i] = (west_read_cmd_pld_in[i].txnid.direction_id == 2'd1) ? west_read_cmd_vld_in[i] : 1'b0 ;
            assign east_read_cmd_pld_out[i] = west_read_cmd_pld_in[i];
        end
    endgenerate




    generate
        for(genvar i=0;i<8;i=i+1)begin
            assign west_write_cmd_vld_out[i] = west_write_cmd_vld_in[i] | east_write_cmd_vld_in[i];
            assign west_write_cmd_pld_out[i] = east_write_cmd_vld_in[i] ? east_write_cmd_pld_in[i] : west_write_cmd_pld_in[i];
        end
    endgenerate
    //assert west_write_cmd_vld_in和east_write_cmd_vld_in不会同时有效

     generate
        for(genvar i=0;i<8;i=i+1)begin
            assign west_data_out[i] = east_data_in_vld ? east_data_in[i] : west_data_in[i];
            assign west_data_out_vld[i] = east_data_in_vld | west_data_in_vld;
        end
    endgenerate

    generate
        for(genvar i=0;i<8;i=i+1)begin
            assign east_data_out[i]     = west_data_in[i] ;
            assign east_data_out_vld[i] = (west_read_cmd_pld_in[i].txnid.direction_id == 2'd1) ?  west_read_cmd_vld_in[i]: 1'b0;//TODO:
        end
    endgenerate


   
    
    





endmodule