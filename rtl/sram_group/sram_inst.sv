module sram_inst 
    import vector_cache_pkg::*;
    (
    input  logic              clk        ,
    input  logic              rst_n      ,
    input  logic              read_vld   ,
    input  sram_inst_cmd_t    read_cmd   ,
    input  logic              write_vld  ,
    input  sram_inst_cmd_t    write_cmd  ,
    
    input  logic  [32-1   :0] wr_data    ,
    output logic  [32-1   :0] rd_data
    
);

    parameter integer unsigned ID = 0       ;
    logic                   en              ;
    logic                   wr_en           ;
    logic   [15     :0]     byte_wr_en      ; // 16 bytes,16bit byte_en
    logic   [127    :0]     ram_rd_data     ;
    logic   [127    :0]     ram_wr_data     ;

    logic                   read_vld_d      ;
    logic   [1      :0]     rd_byte_sel_d   ;
    logic                   rd_mode_d       ;
    logic   [8      :0]     addr            ;
    //logic                   rd_opcode       ;
    //logic                   wr_opcode       ;
    //logic   [1      :0]     linefill_num    ;   // linefill write时的传输次数编号
    //logic   [1      :0]     evict_num       ;   // evict read时的传输次数编号

    //assign linefill_num = write_cmd.req_num; //linefill write时的传输次数编号
    //assign evict_num    = read_cmd.req_num ; //evict read时的传输次数编号
    // enable  
    assign en          = write_vld | read_vld     ;
    assign wr_en       = write_vld                ;
    assign wr_byte_sel = write_cmd.byte_sel       ;
    assign wr_mode     = write_cmd.mode           ;//mode=0,读写连续的32bit; mode=1 每32bit中读一个byte
    assign rd_byte_sel = read_cmd.byte_sel        ;
    assign rd_mode     = read_cmd.mode            ;//mode=0,读写连续的32bit; mode=1 每32bit中读一个byte
//    assign wr_opcode   = write_cmd.opcode         ;//opcode=0,normal write; opcode=1,linefill write
//    assign rd_opcode   = read_cmd.opcode          ;//opcode=0,normal read; opcode=1,evict read
    assign addr        = write_vld ? write_cmd.addr : read_cmd.addr;

    mem_model #(
        .ADDR_WIDTH  (9  ),
        .DATA_WIDTH  (128))
    sram_inst (
      .clk       (clk        ),
      .en        (en         ),
      .wr_en     (wr_en      ),
      .addr      (addr       ),
      .wr_byte_en(byte_wr_en ),
      .wr_data   (ram_wr_data),
      .rd_data   (ram_rd_data)
    );

    // 写
    always_comb begin
        //byte_wr_en  = 16'b0;
        //ram_wr_data = 128'b0;
            if (wr_mode == 1'b0) begin//读写连续的32bit
                case (wr_byte_sel)
                    2'b00: begin
                        byte_wr_en[3:0]    = 4'b1111;
                        ram_wr_data[31:0]  = wr_data;
                    end
                    2'b01: begin
                        byte_wr_en[7:4]    = 4'b1111;
                        ram_wr_data[63:32] = wr_data;
                    end
                    2'b10: begin
                        byte_wr_en[11:8]   = 4'b1111;
                        ram_wr_data[95:64] = wr_data;
                    end
                    2'b11: begin
                        byte_wr_en[15:12]  = 4'b1111;
                        ram_wr_data[127:96]= wr_data;
                    end
                    default: begin
                        byte_wr_en  = 16'b0;
                        ram_wr_data = 128'b0;
                    end
                endcase
            end 
            else if(wr_mode==1'b1) begin//每32bit中写8bit，组成32bit
                case (wr_byte_sel)
                    2'b00: begin
                        byte_wr_en[0]       = 1'b1;
                        byte_wr_en[4]       = 1'b1;
                        byte_wr_en[8]       = 1'b1;
                        byte_wr_en[12]      = 1'b1;
                        ram_wr_data[7:0]    = wr_data[7:0];
                        ram_wr_data[39:32]  = wr_data[15:8];
                        ram_wr_data[71:64]  = wr_data[23:16];
                        ram_wr_data[103:96] = wr_data[31:24];
                    end
                    2'b01: begin
                        byte_wr_en[1]       = 1'b1;
                        byte_wr_en[5]       = 1'b1;
                        byte_wr_en[9]       = 1'b1;
                        byte_wr_en[13]      = 1'b1;
                        ram_wr_data[15:8]   = wr_data[7:0];
                        ram_wr_data[47:40]  = wr_data[15:8];
                        ram_wr_data[79:72]  = wr_data[23:16];
                        ram_wr_data[111:104]= wr_data[31:24];
                    end
                    2'b10: begin
                        byte_wr_en[2]       = 1'b1;
                        byte_wr_en[6]       = 1'b1;
                        byte_wr_en[10]      = 1'b1;
                        byte_wr_en[14]      = 1'b1;
                        ram_wr_data[23:16]  = wr_data[7:0];
                        ram_wr_data[55:48]  = wr_data[15:8];
                        ram_wr_data[87:80]  = wr_data[23:16];
                        ram_wr_data[119:112]= wr_data[31:24];
                    end
                    2'b11: begin
                        byte_wr_en[3]       = 1'b1;
                        byte_wr_en[7]       = 1'b1;
                        byte_wr_en[11]      = 1'b1;
                        byte_wr_en[15]      = 1'b1;
                        ram_wr_data[31:24]  = wr_data[7:0];
                        ram_wr_data[63:56]  = wr_data[15:8];
                        ram_wr_data[95:88]  = wr_data[23:16];
                        ram_wr_data[127:120]= wr_data[31:24];
                    end
                    default: begin
                        byte_wr_en  = 16'b0;
                        ram_wr_data = 128'b0;
                    end
                endcase
            end
        end


    // 读 
    //因为读数据下一拍出，所以要把选择信号打一拍，用于选择读数据
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            read_vld_d <= 'b0;
            rd_mode_d     <= 'b0;
            rd_byte_sel_d <= 'b0;
        end
        else begin
            read_vld_d <= read_vld;
            rd_mode_d     <= rd_mode;
            rd_byte_sel_d <= rd_byte_sel;
        end
    end

    always_comb begin
        //rd_data = 32'b0;
        //if (read_vld_d) begin//normal read
        if (rd_mode_d == 1'b0) begin
            case (rd_byte_sel_d)
                2'b00: rd_data   = ram_rd_data[31:0]  ;
                2'b01: rd_data   = ram_rd_data[63:32] ;
                2'b10: rd_data   = ram_rd_data[95:64] ;
                2'b11: rd_data   = ram_rd_data[127:96];
                default: rd_data = 32'b0;
            endcase
        end 
        else if(rd_mode_d==1'b1)begin
            case (rd_byte_sel_d)
                2'b00: rd_data   = {ram_rd_data[103:96], ram_rd_data[71:64], ram_rd_data[39:32], ram_rd_data[7:0]};
                2'b01: rd_data   = {ram_rd_data[111:104], ram_rd_data[79:72], ram_rd_data[47:40], ram_rd_data[15:8]};
                2'b10: rd_data   = {ram_rd_data[119:112], ram_rd_data[87:80], ram_rd_data[55:48], ram_rd_data[23:16]};
                2'b11: rd_data   = {ram_rd_data[127:120], ram_rd_data[95:88], ram_rd_data[63:56], ram_rd_data[31:24]};
                default: rd_data = 32'b0;
            endcase
        end
    end
        //else if(read_vld && rd_opcode==1'b1)begin//evict read
        //    case (evict_num)
        //        2'b00: rd_data   = ram_rd_data[31:0]  ;
        //        2'b01: rd_data   = ram_rd_data[63:32] ;
        //        2'b10: rd_data   = ram_rd_data[95:64] ;
        //        2'b11: rd_data   = ram_rd_data[127:96];
        //        default: rd_data = 32'b0;
        //    endcase
        //end

    

    always @(posedge clk) begin
        assert (!(read_vld && write_vld))
            else $error("Crossbar conflict: Read and Write are both valid");
    end

endmodule
