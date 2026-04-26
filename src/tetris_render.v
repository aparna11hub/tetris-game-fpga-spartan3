`default_nettype none

module tetris_render (
    input wire clk,
    input wire video_on,
    input wire [9:0] x,
    input wire [9:0] y,
    input wire [2:0] current_p_id, 
    input wire [199:0] active_piece_flat, 
    input wire [199:0] board_flat, 
    input wire [599:0] board_color_flat, 
    input wire [3:0] score_tens,  
    input wire [3:0] score_ones,
    input wire [5:0] btns,
    output reg [1:0] R,
    output reg [1:0] G,
    output reg [1:0] B
);

    wire [3:0] draw_grid_x = (x - 220) / 20;
    wire [4:0] draw_grid_y = (y - 40) / 20;
    wire is_locked = board_flat[(draw_grid_y * 10) + draw_grid_x];
    wire is_active = active_piece_flat[(draw_grid_y * 10) + draw_grid_x];
    
    // --- COMPILER-SAFE COLOR EXTRACTION ---
    wire [2:0] locked_color;
    assign locked_color[0] = board_color_flat[((draw_grid_y * 10) + draw_grid_x) * 3 + 0];
    assign locked_color[1] = board_color_flat[((draw_grid_y * 10) + draw_grid_x) * 3 + 1];
    assign locked_color[2] = board_color_flat[((draw_grid_y * 10) + draw_grid_x) * 3 + 2];

    // --- MULTIPLEXED FONT ENGINE ---
    
    // NEW: "SCORE" text label coordinates!
    wire is_score_lbl = (x >= 440 && x < 520 && y >= 24 && y < 44);
    wire [2:0] lbl_idx = (x - 440) >> 4; // Shift by 4 is the same as dividing by 16 for perfect letter spacing!
    
    wire is_score = (x >= 450 && x < 494 && y >= 50 && y < 70);
    wire is_btn_0 = (x >= 50 && x < 62 && y >= 200 && y < 220); 
    wire is_btn_1 = (x >= 130 && x < 142 && y >= 200 && y < 220); 
    wire is_btn_2 = (x >= 90 && x < 102 && y >= 160 && y < 180); 
    wire is_btn_3 = (x >= 90 && x < 102 && y >= 200 && y < 220); 
    wire is_btn_4 = (x >= 50 && x < 62 && y >= 260 && y < 280); 
    wire is_btn_5 = (x >= 130 && x < 142 && y >= 260 && y < 280); 
    
    wire is_any_text = is_score_lbl | is_score | is_btn_0 | is_btn_1 | is_btn_2 | is_btn_3 | is_btn_4 | is_btn_5;
    
    wire [3:0] f_x = is_score_lbl ? ((x - 440) - (lbl_idx * 16)) / 4 :
                     is_score ? ((x >= 474) ? (x - 474)/4 : (x - 450)/4) :
                     is_btn_0 ? (x - 50)/4 :
                     is_btn_1 ? (x - 130)/4 :
                     is_btn_2 ? (x - 90)/4 :
                     is_btn_3 ? (x - 90)/4 :
                     is_btn_4 ? (x - 50)/4 :
                     is_btn_5 ? (x - 130)/4 : 0;

    wire [3:0] f_y = is_score_lbl ? (y - 24)/4 :
                     is_score ? (y - 50)/4 :
                     is_btn_2 ? (y - 160)/4 :
                     (is_btn_0 | is_btn_1 | is_btn_3) ? (y - 200)/4 :
                     (is_btn_4 | is_btn_5) ? (y - 260)/4 : 0;

    wire [3:0] f_digit = is_score_lbl ? (
                            lbl_idx == 0 ? 4'd5 :  // 'S' (Looks exactly like 5!)
                            lbl_idx == 1 ? 4'd13 : // 'C'
                            lbl_idx == 2 ? 4'd0 :  // 'O' (Looks exactly like 0!)
                            lbl_idx == 3 ? 4'd10 : // 'R'
                            4'd14                  // 'E'
                         ) :
                         is_score ? ((x >= 474) ? score_ones : score_tens) :
                         is_btn_0 ? 4'd0 :
                         is_btn_1 ? 4'd1 :
                         is_btn_2 ? 4'd2 :
                         is_btn_3 ? 4'd3 :
                         is_btn_4 ? 4'd10 : 
                         is_btn_5 ? 4'd11 : 
                         4'd0;
                         
    reg draw_text_pixel;
    always @(*) begin
        draw_text_pixel = 0;
        if (is_any_text && f_x < 3 && f_y < 5) begin
            case (f_digit)
                0: draw_text_pixel = (f_x != 1) || (f_y == 0) || (f_y == 4);
                1: draw_text_pixel = (f_x == 1) || (f_y == 4) || (f_x == 0 && f_y == 1);
                2: draw_text_pixel = (f_y == 0 || f_y == 2 || f_y == 4) || (f_x == 2 && f_y == 1) || (f_x == 0 && f_y == 3);
                3: draw_text_pixel = (f_y == 0 || f_y == 2 || f_y == 4) || (f_x == 2);
                4: draw_text_pixel = (f_x == 2) || (f_y == 2) || (f_x == 0 && f_y < 2);
                5: draw_text_pixel = (f_y == 0 || f_y == 2 || f_y == 4) || (f_x == 0 && f_y == 1) || (f_x == 2 && f_y == 3);
                6: draw_text_pixel = (f_y == 0 || f_y == 2 || f_y == 4) || (f_x == 0) || (f_x == 2 && f_y == 3);
                7: draw_text_pixel = (f_y == 0) || (f_x == 2);
                8: draw_text_pixel = (f_y == 0 || f_y == 2 || f_y == 4) || (f_x == 0) || (f_x == 2);
                9: draw_text_pixel = (f_y == 0 || f_y == 2 || f_y == 4) || (f_x == 2) || (f_x == 0 && f_y == 1);
                10: draw_text_pixel = (f_x == 0) || (f_y == 0) || (f_y == 2 && f_x < 3) || (f_x == 2 && f_y == 1) || (f_x == 1 && f_y == 3) || (f_x == 2 && f_y == 4); 
                11: draw_text_pixel = (f_x == 0) || (f_y == 0) || (f_y == 2) || (f_x == 2 && f_y == 1); 
                13: draw_text_pixel = (f_x == 0) || (f_y == 0) || (f_y == 4); // NEW: Character 'C'
                14: draw_text_pixel = (f_x == 0) || (f_y == 0) || (f_y == 2 && f_x < 2) || (f_y == 4); // NEW: Character 'E'
                default: draw_text_pixel = 0;
            endcase
        end
    end

    // --- BUTTON BACKGROUND BOXES ---
    wire is_box_0 = (x >= 44 && x < 68 && y >= 196 && y < 224); 
    wire is_box_1 = (x >= 124 && x < 148 && y >= 196 && y < 224); 
    wire is_box_2 = (x >= 84 && x < 108 && y >= 156 && y < 184); 
    wire is_box_3 = (x >= 84 && x < 108 && y >= 196 && y < 224); 
    wire is_box_4 = (x >= 44 && x < 68 && y >= 256 && y < 284); 
    wire is_box_5 = (x >= 124 && x < 148 && y >= 256 && y < 284); 
    wire draw_box_bg = is_box_0 | is_box_1 | is_box_2 | is_box_3 | is_box_4 | is_box_5;

    wire is_pressed = (is_box_0 && btns[0]) || 
                      (is_box_1 && btns[1]) || 
                      (is_box_2 && btns[2]) || 
                      (is_box_3 && btns[3]) || 
                      (is_box_4 && btns[4]) || 
                      (is_box_5 && btns[5]);

    always @(posedge clk) begin
        if (~video_on) begin
            R <= 2'b00; G <= 2'b00; B <= 2'b00; 
        end else begin
            
            if (is_any_text && draw_text_pixel) begin
                if (is_pressed) begin
                    R <= 2'b00; G <= 2'b00; B <= 2'b00; 
                end else begin
                    R <= 2'b11; G <= 2'b11; B <= 2'b11; 
                end
            end 
            
            else if (draw_box_bg) begin
                if (is_pressed) begin
                    if (is_box_4) begin R <= 2'b11; G <= 2'b00; B <= 2'b00; end 
                    else if (is_box_5) begin R <= 2'b11; G <= 2'b11; B <= 2'b00; end 
                    else begin R <= 2'b00; G <= 2'b11; B <= 2'b00; end 
                end else begin
                    R <= 2'b01; G <= 2'b01; B <= 2'b01; 
                end
            end

            else if (x >= 220 && x < 420 && y >= 40 && y < 440) begin
                if (is_active) begin
                    case (current_p_id)
                        0: begin R <= 2'b11; G <= 2'b11; B <= 2'b00; end 
                        1: begin R <= 2'b00; G <= 2'b11; B <= 2'b11; end 
                        2: begin R <= 2'b11; G <= 2'b00; B <= 2'b11; end 
                        default: begin R <= 2'b11; G <= 2'b11; B <= 2'b11; end 
                    endcase
                end 
                else if (is_locked) begin
                    case (locked_color)
                        3'd1: begin R <= 2'b11; G <= 2'b11; B <= 2'b00; end 
                        3'd2: begin R <= 2'b00; G <= 2'b11; B <= 2'b11; end 
                        3'd3: begin R <= 2'b11; G <= 2'b00; B <= 2'b11; end 
                        default: begin R <= 2'b11; G <= 2'b11; B <= 2'b11; end 
                    endcase
                end
                else if (y == 80) begin
                    R <= 2'b11; G <= 2'b00; B <= 2'b00;
                end
                else if (
                    x == 220 || x == 240 || x == 260 || x == 280 || x == 300 || 
                    x == 320 || x == 340 || x == 360 || x == 380 || x == 400 ||
                    y == 40  || y == 60  || y == 100 || y == 120 || y == 140 || 
                    y == 160 || y == 180 || y == 200 || y == 220 || y == 240 || 
                    y == 260 || y == 280 || y == 300 || y == 320 || y == 340 || 
                    y == 360 || y == 380 || y == 400 || y == 420
                ) begin
                    R <= 2'b01; G <= 2'b01; B <= 2'b01;
                end
                else begin
                    R <= 2'b00; G <= 2'b00; B <= 2'b00; 
                end
            end 
            
            else if ( ((x == 219 || x == 420) && (y >= 39 && y <= 440)) || 
                      ((y == 39  || y == 440) && (x >= 219 && x <= 420)) ) begin
                R <= 2'b11; G <= 2'b11; B <= 2'b11; 
            end else begin
                R <= 2'b00; G <= 2'b00; B <= 2'b00; 
            end
        end
    end
endmodule
