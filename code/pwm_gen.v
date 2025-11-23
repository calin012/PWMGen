// pwm_gen.v
// PWM generator that observes count_val and produces pwm_out according to FUNCTIONS and compares.
// FUNCTIONS[0] -> alignment left (0) / right (1)
// FUNCTIONS[1] -> aligned (0) / unaligned (1)

module pwm_gen (
    // peripheral clock signals
    input clk,
    input rst_n,
    // PWM signal register configuration
    input pwm_en,
    input[15:0] period,
    input[7:0] functions,
    input[15:0] compare1,
    input[15:0] compare2,
    input[15:0] count_val,
    // top facing signals
    output reg pwm_out
);

    wire align_bit;   // functions[0]
    wire unaligned;   // functions[1]
    assign align_bit = functions[0];
    assign unaligned  = functions[1];

    reg last_count_was_zero;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_out <= 1'b0;
            last_count_was_zero <= 1'b1;
        end else begin
            if (!pwm_en) begin
                // when PWM disabled, freeze
                last_count_was_zero <= (count_val == 16'h0000);
            end else if (unaligned) begin
                // unaligned operation: start low, go high at compare1, low at compare2
                if (count_val == compare1) begin
                    pwm_out <= 1'b1;
                end else if (count_val == compare2) begin
                    pwm_out <= 1'b0;
                end
                last_count_was_zero <= (count_val == 16'h0000);
            end else begin
                // aligned mode
                if (count_val == 16'h0000) begin
                    // beginning of period: set initial state depending on align_bit
                    pwm_out <= (align_bit == 1'b0) ? 1'b1 : 1'b0; // left->1, right->0
                end else if (count_val == compare1) begin
                    // toggle on compare1 (flip to opposite)
                    pwm_out <= ~pwm_out;
                end
                last_count_was_zero <= (count_val == 16'h0000);
            end
        end
    end

endmodule
