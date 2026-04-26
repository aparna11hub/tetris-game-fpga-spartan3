`default_nettype none

module vga_sync (
    input wire clk,
    input wire reset,
    output reg hsync,
    output reg vsync,
    output wire video_on,
    output reg [9:0] x, // Current X pixel
    output reg [9:0] y  // Current Y pixel
);

    parameter HD = 640, HF = 16, HB = 48, HR = 96, HMAX = 799; 
    parameter VD = 480, VF = 10, VB = 33, VR = 2, VMAX = 524; 

    always @(posedge clk) begin
        if (reset) begin
            x <= 0;
            y <= 0;
        end else begin
            if (x == HMAX) begin
                x <= 0;
                if (y == VMAX) y <= 0;
                else y <= y + 1;
            end else begin
                x <= x + 1;
            end
        end
    end

    always @(posedge clk) begin
        hsync <= ~((x >= (HD + HF)) && (x < (HD + HF + HR)));
        vsync <= ~((y >= (VD + VF)) && (y < (VD + VF + VR)));
    end

    assign video_on = (x < HD) && (y < VD);

endmodule
