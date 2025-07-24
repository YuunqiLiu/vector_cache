module xy_switch 
import vector_cache_pkg::*;
    #( 
    parameter integer unsigned BLOCK_ID =0,
    parameter integer unsigned ROW_ID = 0
    )(
    input  logic                clk                                   ,
    input  logic                rst_n                                 ,
    input  logic [1         :0] group_id_col                 [7  :0]  ,
    input  logic [1         :0] group_id_row                 [7  :0]  ,

    input  logic [7         :0] west_read_cmd_in_vld                 ,//txnid的低2bit表示方向：00：west；01：east；10：south；11：north
    input  arb_out_req_t        west_read_cmd_in_pld         [7 :0]  ,
    input  logic [7         :0] east_read_cmd_in_vld                 ,
    input  arb_out_req_t        east_read_cmd_in_pld         [7 :0]  ,

    output logic [7         :0] west_read_cmd_out_vld                ,
    output arb_out_req_t        west_read_cmd_out_pld        [7 :0]  ,
    output logic [7         :0] east_read_cmd_out_vld                ,
    output arb_out_req_t        east_read_cmd_out_pld        [7 :0]  ,


    input  logic [7         :0] west_write_cmd_in_vld                ,
    input  arb_out_req_t        west_write_cmd_in_pld        [7 :0]  ,
    input  logic [7         :0] east_write_cmd_in_vld                ,
    input  arb_out_req_t        east_write_cmd_in_pld        [7 :0]  ,
    input  logic [7         :0] south_write_cmd_in_vld               ,
    input  arb_out_req_t        south_write_cmd_in_pld       [7 :0]  ,
    input  logic [7         :0] north_write_cmd_in_vld               ,
    input  arb_out_req_t        north_write_cmd_in_pld       [7 :0]  ,

    output logic [7         :0] west_write_cmd_out_vld                ,
    output arb_out_req_t        west_write_cmd_out_pld        [7 :0]  ,
    output logic [7         :0] east_write_cmd_out_vld                ,
    output arb_out_req_t        east_write_cmd_out_pld        [7 :0]  ,
        
    output logic [7         :0] south_write_cmd_out_vld               ,
    output arb_out_req_t        south_write_cmd_out_pld       [7 :0]  ,
    output logic [7         :0] north_write_cmd_out_vld               ,
    output arb_out_req_t        north_write_cmd_out_pld       [7 :0]  ,

    input  logic [7         :0] west_data_in_vld                      ,
    input  data_pld_t           west_data_in                  [7  :0] ,
    output logic [7         :0] west_data_out_vld                     ,
    output data_pld_t           west_data_out                 [7  :0] ,
     
    input  logic [7         :0] east_data_in_vld                      ,
    input  data_pld_t           east_data_in                  [7  :0] ,
    output logic [7         :0] east_data_out_vld                     ,
    output data_pld_t           east_data_out                 [7  :0] ,
 
    input  logic [7         :0] south_data_in_vld                     ,
    input  data_pld_t           south_data_in                 [7  :0] ,
    output logic [7         :0] south_data_out_vld                    ,
    output data_pld_t           south_data_out                [7  :0] ,
 
    input  logic [7         :0] north_data_in_vld                     ,
    input  data_pld_t           north_data_in                 [7  :0] ,
    output logic [7         :0] north_data_out_vld                    ,
    output data_pld_t           north_data_out                [7  :0]  

);

    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk or negedge rst_n)begin
                if(!rst_n)begin
                    west_read_cmd_out_vld[i]    <= 'b0;
                    west_read_cmd_out_pld[i]    <= 'b0;
                    east_read_cmd_out_vld[i]    <= 'b0;
                    east_read_cmd_out_pld[i]    <= 'b0;
                end
                else begin
                    west_read_cmd_out_vld[i]    <= east_read_cmd_in_vld[i];
                    west_read_cmd_out_pld[i]    <= east_read_cmd_in_pld[i];
                    east_read_cmd_out_vld[i]    <= west_read_cmd_in_vld[i];
                    east_read_cmd_out_pld[i]    <= west_read_cmd_in_pld[i];
                end
            end
        end
    endgenerate

    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk or negedge rst_n) begin

                
                    west_write_cmd_out_vld[i]  <= east_write_cmd_in_vld[i];
                    west_write_cmd_out_pld[i]  <= east_write_cmd_in_pld[i];

                    south_write_cmd_out_vld[i]  <= 'b0;
                    south_write_cmd_out_pld[i]  <= 'b0;
                    north_write_cmd_out_vld[i]  <= 'b0;
                    north_write_cmd_out_pld[i]  <= 'b0;
                if(!rst_n)begin
                    east_write_cmd_out_vld[i]   <= 'b0;//？
                    east_write_cmd_out_pld[i]   <= 'b0;//？
                end
                else if(BLOCK_ID == ROW_ID)begin//对角线的block


                    east_write_cmd_out_vld[i] <= west_write_cmd_in_vld[i] | north_write_cmd_in_vld[i] | south_write_cmd_in_vld[i];
                    east_write_cmd_out_pld[i] <=    west_write_cmd_in_vld[i]  ? west_write_cmd_in_pld[i] :
                                                    north_write_cmd_in_vld[i] ? north_write_cmd_in_pld[i] : 
                                                                                south_write_cmd_in_pld[i]; // if east_write_cmd_in_vld[i] is valid, then it will be used, otherwise use the first valid one from west, north or south

                end
                else begin//不在对角线的block，west-east && north-south
                    west_write_cmd_out_vld[i]  <= east_write_cmd_in_vld[i];
                    west_write_cmd_out_pld[i]  <= east_write_cmd_in_pld[i];
                    east_write_cmd_out_vld[i]  <= west_write_cmd_in_vld[i];
                    east_write_cmd_out_pld[i]  <= west_write_cmd_in_pld[i];
                    south_write_cmd_out_vld[i] <= north_write_cmd_in_vld[i];
                    south_write_cmd_out_pld[i] <= north_write_cmd_in_pld[i];
                    north_write_cmd_out_vld[i] <= south_write_cmd_in_vld[i];
                    north_write_cmd_out_pld[i] <= south_write_cmd_in_pld[i];
                end
            end
        end
    endgenerate

    //=====================================================================
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk or negedge rst_n) begin
                if(!rst_n)begin
                    west_data_out[i]       <= 'b0;
                    west_data_out_vld[i]   <= 'b0;
                    east_data_out[i]       <= 'b0;
                    east_data_out_vld[i]   <= 'b0;
                    south_data_out[i]      <= 'b0;
                    south_data_out_vld[i]  <= 'b0;
                    north_data_out[i]      <= 'b0;
                    north_data_out_vld[i]  <= 'b0;
                end
                //if(group_id_row[i]==group_id_col[i])begin//对角线的block
                else if(BLOCK_ID == ROW_ID)begin//对角线的block
                    east_data_out_vld[i] <= north_data_in_vld[i] | south_data_in_vld[i] | west_data_in_vld[i];
                    east_data_out[i]     <= north_data_in_vld[i] ? north_data_in[i] :
                                            south_data_in_vld[i] ? south_data_in[i] : west_data_in[i] ;
;
                    west_data_out_vld[i] <=  east_data_in_vld[i] && (east_data_in[i].cmd_pld.txnid.direction_id==2'd0);
                    west_data_out[i]     <=  east_data_in[i];

                    north_data_out_vld[i]<=  east_data_in_vld[i] && (east_data_in[i].cmd_pld.txnid.direction_id==2'd3);//north
                    north_data_out[i]    <=  east_data_in[i];

                    south_data_out_vld[i]<=  east_data_in_vld[i] && (east_data_in[i].cmd_pld.txnid.direction_id==2'd2);//south
                    south_data_out[i]    <=  east_data_in[i];
                end
                else begin
                    west_data_out[i]      <= east_data_in[i];
                    west_data_out_vld[i]  <= east_data_in_vld[i];
                    east_data_out[i]      <= west_data_in[i];
                    east_data_out_vld[i]  <= west_data_in_vld[i];
                    south_data_out[i]     <= north_data_in[i];
                    south_data_out_vld[i] <= north_data_in_vld[i];
                    north_data_out[i]     <= south_data_in[i];
                    north_data_out_vld[i] <= south_data_in_vld[i];
                end
            end
        end
    endgenerate

    //===========assertion write_vld , read_vld在同channel不会同时出现==================
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_comb begin
                assert ((west_write_cmd_in_vld[i] + south_write_cmd_in_vld[i] + north_write_cmd_in_vld[i])<=1'b1)
                else $error(" ERROR: only one cmd can be valid,write_cmd_vld conflict error");
            end
        end
    endgenerate

    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_comb begin
                assert (west_write_cmd_in_vld[i] && west_read_cmd_in_vld[i])
                else $error("ERROR: read/write conflict ,can not both valid ! ");
            end
        end
    endgenerate
    //=====================================================================
    //===========assertion 四个方向的data不会冲突============================
    //west_data,north_data,south_data不会同时出现在该block的同一个channel
    
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_comb begin
                assert ((west_data_in_vld[i] + south_data_in_vld[i] + north_data_in_vld[i])<=1'b1)
                else $error( " ERROR: data_in can not be valid more than one , data_vld conflict error");
            end
        end
    endgenerate
            

endmodule

