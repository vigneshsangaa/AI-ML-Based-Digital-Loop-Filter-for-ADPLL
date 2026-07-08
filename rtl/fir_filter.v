`timescale 1ns / 1ps
// ============================================================
//  FIR Filter - NN3 (Balanced) Coefficients
//  Derived from ANN-based design (Modified Backpropagation)
//  Source: FIR_FILTER__1_.ipynb - Section 9/10
//
//  Parameters:
//    N_TAPS  = 25          (filter order = 25)
//    N2      =  4          (input data width, 4-bit signed TDC)
//    N_COEFF = 12          (coefficient precision, Q1.12)
//    N3      = 12          (output accumulator width)
//
//  Quantization:
//    SCALE = 2^(12-1) - 1 = 2047
//    Accumulator needs 16 bits (max_accum = 25704 × 8 = 205632)
//    Output is full 32-bit signed accumulator
// ============================================================
module fir_filter #(    
    parameter N_TAPS = 25,   // number of filter taps
    parameter N2     =  4,   // input/sample bit width (4-bit signed)
    parameter N_COEFF= 12,   // coefficient bit width  (Q1.12)
    parameter N3     = 12,   // output accumulator width
    parameter SHIFT = 6) (
    input  wire signed [N2-1  : 0] input_data,
    input  wire                    CLK,
    input  wire                    RST,
    input  wire                    Enable,
    output wire signed [N3-1  : 0] output_data,
    output wire signed [N2-1  : 0] SampleT
);



    integer i;

    // ── NN3 (Balanced) Coefficients - Q1.12, SCALE=2047 ──────────────────
    wire signed [N_COEFF-1 : 0] b [0:N_TAPS-1];

assign b[ 0] = 12'b1111_1101_0111;  //   -41
assign b[ 1] = 12'b1111_1011_0000;  //   -80
assign b[ 2] = 12'b1111_1000_1101;  //  -115
assign b[ 3] = 12'b1111_0111_1101;  //  -131
assign b[ 4] = 12'b1111_1000_1111;  //  -113
assign b[ 5] = 12'b1111_1100_1000;  //   -56
assign b[ 6] = 12'b0000_0010_0101;  //    37
assign b[ 7] = 12'b0000_1001_1001;  //   153
assign b[ 8] = 12'b0001_0000_1011;  //   267
assign b[ 9] = 12'b0001_0110_0011;  //   355
assign b[10] = 12'b0001_1000_1110;  //   398
assign b[11] = 12'b0001_1000_0010;  //   386
assign b[12] = 12'b0001_0100_0110;  //   326
assign b[13] = 12'b0000_1110_1001;  //   233
assign b[14] = 12'b0000_1000_0011;  //   131
assign b[15] = 12'b0000_0010_1100;  //    44
assign b[16] = 12'b1111_1111_0101;  //   -11
assign b[17] = 12'b1111_1110_0010;  //   -30
assign b[18] = 12'b1111_1110_1110;  //   -18
assign b[19] = 12'b0000_0000_1101;  //    13
assign b[20] = 12'b0000_0010_1101;  //    45
assign b[21] = 12'b0000_0100_0011;  //    67
assign b[22] = 12'b0000_0100_0111;  //    71
assign b[23] = 12'b0000_0011_1011;  //    59
assign b[24] = 12'b0000_0010_0101;  //    37

    // ── Sample delay line (shift register) ───────────────────────────────
    reg signed [N2-1 : 0] samples [0:N_TAPS-1];

    // ── Output accumulator register ───────────────────────────────────────
    reg signed [31 : 0] output_data_reg;

    always @(posedge CLK) begin
        if (RST == 1'b1) begin
            for (i = 0; i < N_TAPS; i = i + 1)
                samples[i] <= 0;
            output_data_reg <= 0;
        end
        else if (Enable == 1'b1) begin
            // Shift delay line
            for (i = N_TAPS-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];
            samples[0] <= input_data;
            output_data_reg = 0;
            
            output_data_reg = $signed(b[0]) * $signed(input_data);
            
            for (i = 1; i < N_TAPS; i = i + 1)
                output_data_reg = output_data_reg + $signed(b[i]) * $signed(samples[N_TAPS-i]);
        end
    end

    assign output_data = output_data_reg[N3+SHIFT-1 : SHIFT];
    assign SampleT     = samples[0];

endmodule