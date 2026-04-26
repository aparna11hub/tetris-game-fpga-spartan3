`default_nettype none

module tt_um_vga_example (
    input  wire [7:0] ui_in,    
    output wire [7:0] uo_out,   
    input  wire [7:0] uio_in,   
    output wire [7:0] uio_out,  
    output wire [7:0] uio_oe,   
    input  wire       ena,      
    input  wire       clk,      
    input  wire       rst_n     
);

    assign uio_out = 0;
    assign uio_oe  = 0;

    wire reset = !rst_n;

    wire hsync;
    wire vsync;
    wire video_on;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    
    wire [199:0] board_flat; 
    wire [599:0] board_color_flat; // <--- NEW: 600-bit color memory
    wire [199:0] active_piece_flat;
    wire [2:0] current_p_id;
    wire [3:0] score_tens; 
    wire [3:0] score_ones; 
    wire [1:0] R, G, B;

    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

    vga_sync display_timer (
        .clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync),
        .video_on(video_on), .x(pixel_x), .y(pixel_y)
    );

    tetris_logic game_brain (
        .clk(clk), .reset(reset),
        .btn_left(ui_in[0]), .btn_right(ui_in[1]), 
        .btn_up(ui_in[2]), .btn_down(ui_in[3]), 
        .btn_reset(ui_in[4]), .btn_pause(ui_in[5]),
        .current_p_id(current_p_id),            
        .active_piece_flat(active_piece_flat),  
        .board_flat(board_flat),
        .board_color_flat(board_color_flat), // <--- Hooked up
        .score_tens(score_tens), 
        .score_ones(score_ones)  
    );

    tetris_render pixel_painter (
        .clk(clk), .video_on(video_on), .x(pixel_x), .y(pixel_y),
        .current_p_id(current_p_id),           
        .active_piece_flat(active_piece_flat), 
        .board_flat(board_flat), 
        .board_color_flat(board_color_flat), // <--- Hooked up
        .score_tens(score_tens), 
        .score_ones(score_ones), 
        .btns(ui_in[5:0]),       
        .R(R), .G(G), .B(B)
    );

endmodule
