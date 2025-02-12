/* *******************************************************************
 * Generate 16bit sample (mono).
 * Sample data must by available all the time whenever HDMI wants to read it (!)
*/

module gen_audio(
  input wire I_clk_audio,
  input wire I_reset_n,
  output wire [15:0] sample
)/*synthesis syn_romstyle="distributed_rom"*/;

  // Sinus tome 1kHz assuming 48kHz audio clock

  wire [15:0] samples[47:0] = {
    16'd0, 16'd280, 16'd1116, 16'd2494, 16'd4390, 16'd6771, 16'd9597, 16'd12820,
    16'd16384, 16'd20228, 16'd24287, 16'd28490, 16'd32768, 16'd37045, 16'd41248, 16'd45307,
    16'd49152, 16'd52715, 16'd55938, 16'd58764, 16'd61145, 16'd63041, 16'd64419, 16'd65255,
    16'd65535, 16'd65255, 16'd64419, 16'd63041, 16'd61145, 16'd58764, 16'd55938, 16'd52715,
    16'd49152, 16'd45307, 16'd41248, 16'd37045, 16'd32768, 16'd28490, 16'd24287, 16'd20228,
    16'd16384, 16'd12820, 16'd9597, 16'd6771, 16'd4390, 16'd2494, 16'd1116, 16'd280
  };

  reg [15:0] sample_r = 16'd0;
  reg [5:0] sample_idx = 6'd0;
  wire [5:0] sample_idx_plus1 = sample_idx + 1'b1;
  always@(posedge I_clk_audio, negedge I_reset_n)
  begin
    if (!I_reset_n) begin
      sample_idx <= 6'd0;
      sample_r <= 16'd0;
    end else begin
      sample_r <= samples[sample_idx];
      sample_idx <= (sample_idx == 'd47) ? 6'd0 : sample_idx_plus1;
    end
  end

  assign sample = sample_r;
endmodule
 