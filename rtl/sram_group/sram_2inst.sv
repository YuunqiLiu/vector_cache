module sram_2inst
    import vector_cache_pkg::*;
    (
    input  logic                clk         ,
    input  logic                rst_n       ,

    input  logic                read_vld_a  ,
    input  sram_inst_cmd_t      read_cmd_a  ,
    input  logic                write_vld_a ,
    input  sram_inst_cmd_t      write_cmd_a ,
    input  logic [31     :0]    wr_data_a   ,

    input  logic                read_vld_b  ,
    input  sram_inst_cmd_t      read_cmd_b  ,
    input  logic                write_vld_b ,
    input  sram_inst_cmd_t      write_cmd_b ,
    input  logic [31     :0]    wr_data_b   ,

    output logic [31     :0]    rd_data_a   ,
    output logic [31     :0]    rd_data_b

);

    logic                 read_sel        ;  //cross sel
    logic                 write_sel       ;
    logic [31         :0] sram1_wr_data   ;
    logic [31         :0] sram1_rd_data   ;
    logic                 sram1_read_vld  ;
    sram_inst_cmd_t       sram1_read_cmd  ;
    logic                 sram1_write_vld ;
    sram_inst_cmd_t       sram1_write_cmd ;

    logic [31         :0] sram2_wr_data   ;
    logic [31         :0] sram2_rd_data   ;
    logic                 sram2_read_vld  ;
    sram_inst_cmd_t       sram2_read_cmd  ;
    logic                 sram2_write_vld ;
    sram_inst_cmd_t       sram2_write_cmd ;


    //assign read_sel = read_cmd_a.addr[9];//地址最高位作为2块sram的选择
    //assign write_sel = write_cmd_a.addr[9];
    assign read_sel  = read_cmd_a.dest_ram_id[0];
    assign write_sel = write_cmd_a.dest_ram_id[0];
    
    always_ff@(posedge clk)begin
        if(read_cmd_a.dest_ram_id[0] && read_cmd_b.dest_ram_id[0])begin
            $error("ERROR: 2 requset in one hash group conflict error");
        end
        else if(read_cmd_a.dest_ram_id[0]==1'b0 && read_cmd_b.dest_ram_id[0]==1'b0)begin
            $error("ERROR: 2 requset in one hash group conflict error");
        end
    end

    always_comb begin
        if (read_sel) begin
            sram1_read_cmd = read_cmd_a  ;
            sram1_read_vld = read_vld_a  ;

            sram2_read_cmd = read_cmd_b  ;
            sram2_read_vld = read_vld_b  ;
        end 
        else begin
            sram1_read_cmd = read_cmd_b  ;
            sram1_read_vld = read_vld_b  ;

            sram2_read_cmd = read_cmd_a  ;
            sram2_read_vld = read_vld_a  ;
        end
    end

    always_comb begin
        if (write_sel) begin
            sram1_write_cmd = write_cmd_a ;
            sram1_wr_data   = wr_data_a   ;
            sram1_write_vld = write_vld_a ;

            sram2_write_cmd = write_cmd_b ;
            sram2_wr_data   = wr_data_b   ;
            sram2_write_vld = write_vld_b ;
        end 
        else begin
            sram1_write_cmd = write_cmd_b ;
            sram1_wr_data   = wr_data_b   ;
            sram1_write_vld = write_vld_b ;

            sram2_write_cmd = write_cmd_a ;
            sram2_wr_data   = wr_data_a   ;
            sram2_write_vld = write_vld_a ;
        end
    end
    
   

    
    sram_inst u_sram_inst_a (
        .clk      (clk              ),
        .rst_n    (rst_n            ),
        .read_vld (sram1_read_vld   ),
        .read_cmd (sram1_read_cmd   ),
        .write_vld(sram1_write_vld  ),
        .write_cmd(sram1_write_cmd  ),
        .wr_data  (sram1_wr_data    ),
        .rd_data  (sram1_rd_data    )
    );
    sram_inst u_sram_inst_b (
        .clk      (clk              ),
        .rst_n    (rst_n            ),
        .read_vld (sram2_read_vld   ),
        .read_cmd (sram2_read_cmd   ),
        .write_vld(sram2_write_vld  ),
        .write_cmd(sram2_write_cmd  ),
        .wr_data  (sram2_wr_data    ),
        .rd_data  (sram2_rd_data    )
    );



    always_comb begin
        if (read_sel_d) begin
            rd_data_a = sram1_rd_data;
            rd_data_b = sram2_rd_data;
        end else begin
            rd_data_a = sram2_rd_data;
            rd_data_b = sram1_rd_data;
        end
    end


   
endmodule
