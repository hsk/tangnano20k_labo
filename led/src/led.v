module top(input clk, output led);
    reg led_out = 1'd0;
    assign led = led_out;
    reg clk1sec;
    reg [23:0] count1sec = 'd0;

    always @(posedge clk)
        if (count1sec < 27000000/2) begin
            count1sec <= count1sec + 'd1;
            clk1sec <= 'd0;
        end else begin
            count1sec <= 'd0;
            clk1sec <= 'd1;
        end

    always @(posedge clk)
        if (clk1sec) led_out <= ~led_out;
endmodule
