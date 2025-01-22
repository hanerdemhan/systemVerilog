// LED blink with 50MHz clock - SystemVerilog version

module blink (
    input logic clk,            // Clock input
    output logic LED            // LED output
);

    // Counter to track clock cycles
    logic [31:0] counter;

    // Register to hold the LED status
    logic LED_status;

    // Initialization process
    initial begin
        counter = 32'b0;       // Initialize counter to 0
        LED_status = 1'b0;     // Initialize LED status to off
    end

    // Always block triggered on the rising edge of the clock
    always_ff @ (posedge clk) begin
        counter <= counter + 1; // Increment the counter

        // Check if the counter has reached the threshold
        if (counter >= 50000000) begin
            LED_status <= ~LED_status; // Toggle the LED status
            counter <= 32'b0;         // Reset the counter
        end
    end

    // Continuous assignment for the LED output
    assign LED = LED_status;

endmodule
