`default_nettype none

module tetris_logic (
    input wire clk,
    input wire reset,
    input wire btn_left,
    input wire btn_right,
    input wire btn_down,
    input wire btn_up, 
    input wire btn_reset, 
    input wire btn_pause, 
    output wire [2:0] current_p_id, 
    output wire [199:0] active_piece_flat, 
    output wire [199:0] board_flat,
    output wire [599:0] board_color_flat, 
    output reg [3:0] score_tens, 
    output reg [3:0] score_ones  
);

    reg [22:0] tick_counter;
    wire [22:0] tick_max = btn_down ? 23'd500_000 : 23'd3_500_000;
    wire game_tick = (tick_counter >= tick_max); 

    reg [3:0] grid_x; 
    reg [4:0] grid_y; 
    
    reg [199:0] board; 
    assign board_flat = board; 
    
    reg [599:0] board_color;
    assign board_color_flat = board_color;

    reg [2:0] p_id; 
    reg [1:0] rot;  
    assign current_p_id = p_id;

    reg last_left, last_right, last_up, last_down, last_reset, last_pause;

    wire move_left  = btn_left  ^ last_left;
    wire move_right = btn_right ^ last_right;
    wire move_up    = btn_up    ^ last_up;
    wire move_down  = btn_down  ^ last_down;
    wire do_reset   = btn_reset ^ last_reset;
    wire do_pause   = btn_pause ^ last_pause;

    reg [3:0] dx0, dy0, dx1, dy1, dx2, dy2, dx3, dy3;
    always @(*) begin
        dx0=0; dy0=0; dx1=1; dy1=0; dx2=0; dy2=1; dx3=1; dy3=1; 
        case (p_id)
            0: begin dx0=0; dy0=0; dx1=1; dy1=0; dx2=0; dy2=1; dx3=1; dy3=1; end 
            1: if (rot[0]==0) begin dx0=0; dy0=0; dx1=1; dy1=0; dx2=2; dy2=0; dx3=3; dy3=0; end 
               else           begin dx0=0; dy0=0; dx1=0; dy1=1; dx2=0; dy2=2; dx3=0; dy3=3; end 
            2: case (rot) 
                 0: begin dx0=1; dy0=0; dx1=0; dy1=1; dx2=1; dy2=1; dx3=2; dy3=1; end
                 1: begin dx0=1; dy0=0; dx1=1; dy1=1; dx2=2; dy2=1; dx3=1; dy3=2; end
                 2: begin dx0=0; dy0=1; dx1=1; dy1=1; dx2=2; dy2=1; dx3=1; dy3=2; end
                 3: begin dx0=1; dy0=0; dx1=0; dy1=1; dx2=1; dy2=1; dx3=1; dy3=2; end
               endcase
        endcase
    end

    wire [4:0] ax0 = grid_x + dx0; wire [4:0] ay0 = grid_y + dy0;
    wire [4:0] ax1 = grid_x + dx1; wire [4:0] ay1 = grid_y + dy1;
    wire [4:0] ax2 = grid_x + dx2; wire [4:0] ay2 = grid_y + dy2;
    wire [4:0] ax3 = grid_x + dx3; wire [4:0] ay3 = grid_y + dy3;

    reg [199:0] active_piece;
    assign active_piece_flat = active_piece;
    always @(*) begin
        active_piece = 200'b0;
        if (ay0 < 20 && ax0 < 10) active_piece[(ay0*10)+ax0] = 1'b1;
        if (ay1 < 20 && ax1 < 10) active_piece[(ay1*10)+ax1] = 1'b1;
        if (ay2 < 20 && ax2 < 10) active_piece[(ay2*10)+ax2] = 1'b1;
        if (ay3 < 20 && ax3 < 10) active_piece[(ay3*10)+ax3] = 1'b1;
    end

    wire hit_bottom = (ay0 >= 19) || (ay1 >= 19) || (ay2 >= 19) || (ay3 >= 19);
    wire hit_block_down = (ay0 < 19 && board[((ay0+1)*10)+ax0]) ||
                          (ay1 < 19 && board[((ay1+1)*10)+ax1]) ||
                          (ay2 < 19 && board[((ay2+1)*10)+ax2]) ||
                          (ay3 < 19 && board[((ay3+1)*10)+ax3]);
    wire lock_piece = hit_bottom || hit_block_down;

    wire can_move_left = (ax0 > 0 && !board[(ay0*10)+ax0-1]) && (ax1 > 0 && !board[(ay1*10)+ax1-1]) &&
                         (ax2 > 0 && !board[(ay2*10)+ax2-1]) && (ax3 > 0 && !board[(ay3*10)+ax3-1]);
    wire can_move_right = (ax0 < 9 && !board[(ay0*10)+ax0+1]) && (ax1 < 9 && !board[(ay1*10)+ax1+1]) &&
                          (ax2 < 9 && !board[(ay2*10)+ax2+1]) && (ax3 < 9 && !board[(ay3*10)+ax3+1]);

    integer i, j, dest_row, lines_cleared; 
    reg [199:0] temp_board, next_board; 
    reg [599:0] temp_board_color, next_board_color; 
    reg line_full;

    always @(posedge clk) begin
        if (reset || btn_reset) begin
            tick_counter <= 0; grid_x <= 4; grid_y <= 0; 
            board <= 200'b0; 
            board_color <= 600'b0; 
            p_id <= 0; rot <= 0;
            score_tens <= 0; score_ones <= 0; 
            last_left <= 0; last_right <= 0; last_up <= 0; last_down <= 0; last_reset <= 0; last_pause <= 0;
            
        end else if (!btn_pause) begin
            last_left <= btn_left; last_right <= btn_right; last_up <= btn_up; 
            last_down <= btn_down; last_reset <= btn_reset; last_pause <= btn_pause;

            if (move_left && can_move_left) grid_x <= grid_x - 1; 
            if (move_right && can_move_right) grid_x <= grid_x + 1; 
            if (move_up) begin 
                rot <= rot + 1; 
                if (grid_x > 6) grid_x <= 6; 
            end

            if (game_tick) begin
                tick_counter <= 0;
                
                if (lock_piece) begin
                    temp_board = board | active_piece; 
                    
                    // --- COMPILER-SAFE COLOR SAVING ---
                    temp_board_color = board_color;
                    if (ay0 < 20 && ax0 < 10) begin
                        temp_board_color[((ay0*10)+ax0)*3 + 0] = (p_id == 0) || (p_id == 2);
                        temp_board_color[((ay0*10)+ax0)*3 + 1] = (p_id == 1) || (p_id == 2);
                        temp_board_color[((ay0*10)+ax0)*3 + 2] = 1'b0;
                    end
                    if (ay1 < 20 && ax1 < 10) begin
                        temp_board_color[((ay1*10)+ax1)*3 + 0] = (p_id == 0) || (p_id == 2);
                        temp_board_color[((ay1*10)+ax1)*3 + 1] = (p_id == 1) || (p_id == 2);
                        temp_board_color[((ay1*10)+ax1)*3 + 2] = 1'b0;
                    end
                    if (ay2 < 20 && ax2 < 10) begin
                        temp_board_color[((ay2*10)+ax2)*3 + 0] = (p_id == 0) || (p_id == 2);
                        temp_board_color[((ay2*10)+ax2)*3 + 1] = (p_id == 1) || (p_id == 2);
                        temp_board_color[((ay2*10)+ax2)*3 + 2] = 1'b0;
                    end
                    if (ay3 < 20 && ax3 < 10) begin
                        temp_board_color[((ay3*10)+ax3)*3 + 0] = (p_id == 0) || (p_id == 2);
                        temp_board_color[((ay3*10)+ax3)*3 + 1] = (p_id == 1) || (p_id == 2);
                        temp_board_color[((ay3*10)+ax3)*3 + 2] = 1'b0;
                    end

                    next_board = 200'b0; 
                    next_board_color = 600'b0; 
                    dest_row = 19;       
                    lines_cleared = 0; 

                    for (i = 19; i >= 0; i = i - 1) begin
                        line_full = 1'b1;
                        for (j = 0; j < 10; j = j + 1) begin
                            if (temp_board[(i * 10) + j] == 1'b0) line_full = 1'b0;
                        end
                        if (!line_full) begin
                            for (j = 0; j < 10; j = j + 1) begin
                                next_board[(dest_row * 10) + j] = temp_board[(i * 10) + j];
                                next_board_color[((dest_row * 10) + j)*3]     = temp_board_color[((i * 10) + j)*3];
                                next_board_color[((dest_row * 10) + j)*3 + 1] = temp_board_color[((i * 10) + j)*3 + 1];
                                next_board_color[((dest_row * 10) + j)*3 + 2] = temp_board_color[((i * 10) + j)*3 + 2];
                            end
                            dest_row = dest_row - 1;
                        end else begin
                            lines_cleared = lines_cleared + 1; 
                        end
                    end

                    if (next_board[4] || next_board[5] || next_board[14] || next_board[15]) begin
                        board <= 200'b0; 
                        board_color <= 600'b0; 
                        score_tens <= 0; score_ones <= 0;
                    end else begin
                        board <= next_board; 
                        board_color <= next_board_color; 
                        
                        if (lines_cleared > 0) begin
                            if (score_ones + lines_cleared >= 10) begin
                                score_ones <= score_ones + lines_cleared - 10;
                                if (score_tens < 9) score_tens <= score_tens + 1;
                            end else begin
                                score_ones <= score_ones + lines_cleared;
                            end
                        end
                    end
                    
                    grid_y <= 0; grid_x <= 4; rot <= 0;
                    p_id <= (p_id == 2) ? 0 : p_id + 1; 
                end 
                else begin
                    grid_y <= grid_y + 1; 
                end
            end else begin
                tick_counter <= tick_counter + 1;
            end
        end
    end
endmodule
