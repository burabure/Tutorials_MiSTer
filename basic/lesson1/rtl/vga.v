
// A simple system-on-a-chip (SoC) for the MiST
// (c) 2015 Till Harbaum

// VGA controller generating 160x100 pixles. The VGA mode ised is 640x480
// combining every 4 row and column

// http://tinyvga.com/vga-timing/640x480@60Hz

module vga (
    // pixel clock
    input pclk,
    // color
    input [7:0] color,
    // VGA output
    output reg hs,
    output reg vs,
    output [7:0] r,
    output [7:0] g,
    output [7:0] b,
    output VGA_DE
);

  // g   Sega Mega Drive NTSC  320x240@60         426    262      15.7277 - -       6.700       16    31   59      4    3   15        arcade/game
  // g   TurboGrafx-16 NTSC    352x240@60         469    262      15.7420 - -       7.383       18    34   65      4    3   15        arcade/game modelines; videogame, TurboGrafx-16, PC-Engine, game console

  parameter H = 320;  // width of visible area
  parameter HFP = 16;  // unused time before hsync
  parameter HS = 31;  // width of hsync
  parameter HBP = 59;  // unused time after hsync

  parameter V = 240;  // height of visible area
  parameter VFP = 4;  // unused time before vsync
  parameter VS = 3;  // width of vsync
  parameter VBP = 15;  // unused time after vsync


  reg [9:0] h_cnt;  // horizontal pixel counter
  reg [9:0] v_cnt;  // vertical pixel counter
  reg       hblank;  // horizontal blank registry
  reg       vblank;  // vertical blank registry


  // --- Sync and Counters
  always @(posedge pclk) begin
    // --- Horizontal counter
    if (h_cnt == H + HFP + HS + HBP - 1) h_cnt <= 10'b0;
    else h_cnt <= h_cnt + 10'b1;

    // --- Generate negative hsync signal
    if (h_cnt == H + HFP) hs <= 1'b0;
    if (h_cnt == H + HFP + HS) hs <= 1'b1;

    // --- HBlanking register
    if (h_cnt >= H) hblank <= 1'b1;
    else hblank <= 1'b0;


    // --- Vertical counter
    if (h_cnt == H + HFP) begin
      if (v_cnt == VS + VBP + V + VFP - 1) v_cnt <= 10'b0;
      else v_cnt <= v_cnt + 10'b1;
    end

    // --- Generate negative vsync signal
    if (v_cnt == V + VFP) vs <= 1'b0;
    if (v_cnt == V + VFP + VS) vs <= 1'b1;

    // --- VBlanking register
    if (v_cnt >= V) vblank <= 1'b1;
    else vblank <= 1'b0;
  end


  // --- draw bounding box
  reg [7:0] pixel;

  always @(posedge pclk) begin
    // are we on the visible area?
    if ((v_cnt < V) && (h_cnt < H)) begin
      if (h_cnt == 10'b0 || v_cnt == 10'b0) pixel <= 8'b000_111_00;
      else if (h_cnt == H - 1 || v_cnt == V - 1) pixel <= color;
      else pixel <= 8'h00;
    end
  end

  // seperate 8 bits into three colors (332)
  assign r = {pixel[7:5], pixel[7:5], pixel[7:6]};
  assign g = {pixel[4:2], pixel[4:2], pixel[4:3]};
  assign b = {pixel[1:0], pixel[1:0], pixel[1:0], pixel[1:0]};

  // disable video if we're blanking
  assign VGA_DE = ~(hblank | vblank);

endmodule
