// SystemVerilog module with DO-178C compliance
module fsm #( 
        parameter integer CNT_ONESEC = 1_000_000 // Counter threshold for one second
)
(
    input logic i_clk,       // Clock signal
    input logic i_rst_n,     // Reset signal (active low)
    input logic i_data,      // Input data signal

    output logic o_data      // Output data signal
);

    // Counter for detecting positive edges
    logic [$clog2(CNT_ONESEC) - 1 : 0] cnt_posedge;

    // State register
    logic [1:0] state;
 
    // Local parameters for state encoding
    localparam logic [1:0]
        RST  = 2'b00, // Reset state
        IDLE = 2'b10, // Idle state
        CNTR = 2'b11, // Counter active state
        STOP = 2'b10; // Stop state

    // Sequential logic block triggered on the rising edge of the clock
    always_ff @(posedge i_clk) begin
        if (!i_rst_n) begin
            state <= RST;           // Set state to reset
            cnt_posedge <= 0;      // Reset the counter
            o_data <= 0;           // Reset output data
        end else begin
            case (state)
                RST: begin
                    state <= IDLE;  // Transition to idle state
                    cnt_posedge <= 0;
                    o_data <= 0;
                end

                IDLE: begin
                    if (i_data == 1) begin
                        state <= CNTR; // Transition to counter state
                    end else begin
                        state <= IDLE; // Remain in idle state
                    end
                end

                CNTR: begin
                    if (!i_data) begin
                        state <= IDLE; // Transition back to idle state
                    end else if (cnt_posedge == CNT_ONESEC) begin
                        state <= STOP;  // Transition to stop state
                        cnt_posedge <= 0;
                    end else begin
                        cnt_posedge <= cnt_posedge + 1; // Increment counter
                        state <= CNTR; // Remain in counter state
                    end
                end

                STOP: begin
                    o_data <= 1;    // Set output data
                    state <= STOP;  // Remain in stop state
                end

                default: begin
                    state <= RST;   // Default to reset state
                end
            endcase
        end
    end

endmodule
