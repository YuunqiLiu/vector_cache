
module vcache_channel_shift_reg
    import vector_cache_pkg::*;
#(
    parameter integer unsigned CHANNEL_SHIFT_REG_WIDTH = 20
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

    logic [CHANNEL_SHIFT_REG_WIDTH-1:0] channel_shift_reg;

    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            channel_shift_reg <= 'b0 ;
        end                 
        else begin
            channel_shift_reg <= {1'b0, channel_shift_reg[CHANNEL_SHIFT_REG_WIDTH-1:1]};
            if(w_write_en)begin
                channel_shift_reg[WR_CMD_DELAY_WEST]  <= 1'b1;
            end
            if(e_write_en)begin
                channel_shift_reg[WR_CMD_DELAY_EAST]  <= 1'b1;
            end   
            if(s_write_en)begin
                channel_shift_reg[WR_CMD_DELAY_SOUTH] <= 1'b1;
            end   
            if(n_write_en)begin
                channel_shift_reg[WR_CMD_DELAY_NORTH] <= 1'b1;
            end   
            if(lf_write_en)begin
                channel_shift_reg[WR_CMD_DELAY_LINEFILL] <= 1'b1;
            end   
        end
    end


    assign write_permission_w   = channel_shift_reg[WR_CMD_DELAY_WEST        ];
    assign write_permission_e   = channel_shift_reg[WR_CMD_DELAY_EAST        ];
    assign write_permission_s   = channel_shift_reg[WR_CMD_DELAY_SOUTH       ];
    assign write_permission_n   = channel_shift_reg[WR_CMD_DELAY_NORTH       ];
    assign write_permission_lf  = channel_shift_reg[WR_CMD_DELAY_LINEFILL    ];

    assign read_permission      = channel_shift_reg[0];

    //output  logic [CHANNEL_SHIFT_REG_WIDTH-1:0] channel_shift_reg

endmodule