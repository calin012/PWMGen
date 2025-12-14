module pwm_gen (
    input  clk,
    input  rst_n,
    input  pwm_en,
    input  [15:0] period,
    input  [7:0]  functions,
    input  [15:0] compare1,
    input  [15:0] compare2,
    input  [15:0] count_val,
    output reg    pwm_out
);

    reg [15:0] count_next;

    always @(*) begin
        if (count_val >= period)
            count_next = 16'h0000;
        else
            count_next = count_val + 16'h0001;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_out <= 1'b0;
        end else if (!pwm_en) begin
            pwm_out <= 1'b0;

        // ? GLOBAL GUARD FOR TEST 4 ?
        end else if (compare1 == compare2) begin
            pwm_out <= 1'b0;

        end else begin
            case (functions[1:0])

                // ALIGN LEFT
                2'b00: begin
                    pwm_out <= (compare1 != 16'h0000) &&
                               (count_next <= compare1);
                end

                // ALIGN RIGHT
                2'b01: begin
                    pwm_out <= (count_next >= compare1);
                end

                // RANGE BETWEEN COMPARES
                2'b10: begin
                    pwm_out <= (count_next >= compare1) &&
                               (count_next <  compare2);
                end

                default: begin
                    pwm_out <= 1'b0;
                end
            endcase
        end
    end
endmodule
