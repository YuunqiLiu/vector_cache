module vcache_ram_shift_reg
    import vector_cache_pkg::*;
#(
    parameter integer unsigned RAM_SHIFT_REG_WIDTH      = 20,
    parameter integer unsigned RAM_BLOCK_WRITE_DELAY    = 1 ,
    parameter integer unsigned RAM_BLOCK_READ_DELAY     = 1
) (
    input   logic                               clk                     ,    
    input   logic                               rst_n                   ,

    input   logic                               update_en_w             ,
    input   logic                               update_en_e             ,
    input   logic                               update_en_s             ,
    input   logic                               update_en_n             ,
    input   logic                               update_en_lf            ,

    output  logic                               write_permission_w      ,
    output  logic                               write_permission_e      ,
    output  logic                               write_permission_s      ,
    output  logic                               write_permission_n      ,
    output  logic                               write_permission_lf     ,
    
    output  logic                               read_permission   
);

    logic [RAM_SHIFT_REG_WIDTH-1:0] ram_shift_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            ram_shift_reg <= 'b0 ;
        end                 
        else begin
            ram_shift_reg <= {1'b0, ram_shift_reg[RAM_SHIFT_REG_WIDTH-1:1]};
            if(w_sr_update_en)begin
                ram_shift_reg[WR_CMD_DELAY_WEST + RAM_BLOCK_WRITE_DELAY]  <= 1'b1;
            end
            if(e_sr_update_en)begin
                ram_shift_reg[WR_CMD_DELAY_EAST + RAM_BLOCK_WRITE_DELAY]  <= 1'b1;
            end   
            if(s_sr_update_en)begin
                ram_shift_reg[WR_CMD_DELAY_SOUTH + RAM_BLOCK_WRITE_DELAY] <= 1'b1;
            end   
            if(n_sr_update_en)begin
                ram_shift_reg[WR_CMD_DELAY_NORTH + RAM_BLOCK_WRITE_DELAY] <= 1'b1;
            end   
            if(lf_sr_update_en)begin
                ram_shift_reg[WR_CMD_DELAY_LINEFILL + RAM_BLOCK_WRITE_DELAY] <= 1'b1;
            end   
        end
    end

    assign read_permission      = ram_shift_reg[RAM_BLOCK_READ_DELAY];

    assign write_permission_w   = ram_shift_reg[WR_CMD_DELAY_WEST     + RAM_BLOCK_WRITE_DELAY];
    assign write_permission_e   = ram_shift_reg[WR_CMD_DELAY_EAST     + RAM_BLOCK_WRITE_DELAY];
    assign write_permission_s   = ram_shift_reg[WR_CMD_DELAY_SOUTH    + RAM_BLOCK_WRITE_DELAY];
    assign write_permission_n   = ram_shift_reg[WR_CMD_DELAY_NORTH    + RAM_BLOCK_WRITE_DELAY];
    assign write_permission_lf  = ram_shift_reg[WR_CMD_DELAY_LINEFILL + RAM_BLOCK_WRITE_DELAY];


endmodule