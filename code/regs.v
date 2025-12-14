module regs (
    input clk,
    input rst_n,

    input read,
    input write,
    input  [5:0] addr,
    output reg [7:0] data_read,
    input  [7:0] data_write,

    input  [15:0] counter_val,
    output reg [15:0] period,
    output reg en,
    output reg count_reset,
    output reg upnotdown,
    output reg [7:0] prescale,

    output reg pwm_en,
    output reg [7:0] functions,
    output reg [15:0] compare1,
    output reg [15:0] compare2
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period      <= 16'h0000;
            en          <= 1'b0;
            count_reset <= 1'b0;
            upnotdown   <= 1'b1;
            prescale    <= 8'h00;
            pwm_en      <= 1'b0;
            functions   <= 8'h00;
            compare1    <= 16'h0000;
            compare2    <= 16'h0000;
        end else begin
            count_reset <= 1'b0;

            if (write) begin
                case (addr)
                    6'h00: period[7:0]   <= data_write;
                    6'h01: period[15:8]  <= data_write;
                    6'h02: en            <= data_write[0];
                    6'h03: compare1[7:0] <= data_write;
                    6'h04: compare1[15:8]<= data_write;
                    6'h05: compare2[7:0] <= data_write;
                    6'h06: compare2[15:8]<= data_write;
                    6'h07: if (data_write[0]) count_reset <= 1'b1;
                    6'h0A: prescale       <= data_write;
                    6'h0B: upnotdown      <= data_write[0];
                    6'h0C: pwm_en         <= data_write[0];
                    6'h0D: functions      <= data_write;
                    default: ;
                endcase
            end
        end
    end

    // combinational readback
    always @(*) begin
        case (addr)
            6'h00: data_read = period[7:0];
            6'h01: data_read = period[15:8];
            6'h02: data_read = {7'b0, en};
            6'h03: data_read = compare1[7:0];
            6'h04: data_read = compare1[15:8];
            6'h05: data_read = compare2[7:0];
            6'h06: data_read = compare2[15:8];
            6'h07: data_read = 8'h00;
            6'h08: data_read = counter_val[7:0];
            6'h09: data_read = counter_val[15:8];
            6'h0A: data_read = prescale;
            6'h0B: data_read = {7'b0, upnotdown};
            6'h0C: data_read = {7'b0, pwm_en};
            6'h0D: data_read = functions;
            default: data_read = 8'h00;
        endcase
    end

endmodule
