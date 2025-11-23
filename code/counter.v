// counter.v
// Prescaled up/down counter. Period is the terminal count (16-bit).
// prescale register interpretation: prescale value N => increment every 2^N peripheral clocks.

module counter (
    // peripheral clock signals
    input clk,
    input rst_n,
    // register facing signals
    output reg[15:0] count_val,
    input[15:0] period,
    input en,
    input count_reset,
    input upnotdown,
    input[7:0] prescale
);

    // prescale counter: counts from 0 .. prescale_limit-1. When reaches limit-1 it toggles main counter.
    reg [31:0] presc_cnt;
    reg [31:0] presc_limit;

    always @(*) begin
        if (prescale >= 31)
            presc_limit = 32'hFFFFFFFF; // too large -> effectively stop incrementing fast
        else
            presc_limit = (1 << prescale);
        if (presc_limit == 0) presc_limit = 1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_val <= 16'h0000;
            presc_cnt <= 32'h0;
        end else begin
            if (count_reset) begin
                count_val <= 16'h0000;
                presc_cnt <= 32'h0;
            end else if (!en) begin
                // counting disabled -> hold value and reset prescaler
                presc_cnt <= 32'h0;
            end else begin
                // enabled
                if (presc_cnt + 1 >= presc_limit) begin
                    presc_cnt <= 32'h0;
                    // time to step the main counter
                    if (upnotdown) begin
                        // count up
                        if (count_val >= period) begin
                            // overflow wrap to 0
                            count_val <= 16'h0000;
                        end else begin
                            count_val <= count_val + 1'b1;
                        end
                    end else begin
                        // count down
                        if (count_val == 16'h0000) begin
                            // underflow wrap to period
                            count_val <= period;
                        end else begin
                            count_val <= count_val - 1'b1;
                        end
                    end
                end else begin
                    presc_cnt <= presc_cnt + 1'b1;
                end
            end
        end
    end

endmodule
