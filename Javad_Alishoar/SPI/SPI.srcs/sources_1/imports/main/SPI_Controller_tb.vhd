----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/22/2023 02:55:51 PM
-- Design Name: 
-- Module Name: SPI_Controller_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SPI_Controller_tb is
--  Port ( );
end SPI_Controller_tb;

architecture Behavioral of SPI_Controller_tb is
    signal  aclk    : std_logic := '0';
    signal  CS      : std_logic := '1';
    signal  SCK     : std_logic := '0';  
    signal  MOSI    : std_logic := '0';
    signal  Data_In         : unsigned(31 downto 0) := ( others => '0');
    signal  Command_Type    : unsigned(1 downto 0) := ( others => '0');
    signal  MISO    : std_logic := '0';
    signal  Send    : std_logic := '0';
    signal  Busy    : std_logic := '0'; 
    signal  Data_Out        : unsigned(7 downto 0) := ( others => '0');
    
    signal  Data_out_Valid : std_logic := '0';      
    signal  Force_CS    : std_logic := '0';     
    constant    CLOCK_PERIOD    : time := 10 ns;
    constant    T_HOLD          : time := 10 ns;  
    
begin
    SPI_Controller_inst : entity work.SPI_Controller
        port map ( 
                    -- Input Ports - single Bit
                    Clock   => aclk ,
                    Force_CS => Force_CS,
                    MISO    => MOSI,
                    Send    => Send,
                    -- Input Ports - Busses
                    Command_Type => Command_Type,
                    Data_In => Data_In,
                    -- Output ports -- single bit
                    Busy => Busy,
                    CS  => CS,
                    Data_Out_Valid => Data_Out_Valid,
                    MOSI => MOSI,
                    SCK => SCK,
                    -- Output Ports --nBusses
                    Data_Out => Data_Out
                    );

clock_gen:  process
                begin
                    aclk <= '0';
                    wait for CLOCK_PERIOD; 
                    loop
                        aclk <= '0';
                        wait for CLOCK_PERIOD/2;
                        aclk <= '1';
                        wait for CLOCK_PERIOD/2;
                    end loop;
            end process clock_gen;  

stimul: process
            begin
                -- Driver inputs T_HOLD time after rising edge of clock
                wait until rising_edge(aclk);
                wait for T_HOLD;
                -- Run for long enough to produce 5 period of outputs Test_Bench
                wait for CLOCK_PERIOD*50;
                    Force_CS <= '1';
                    MISO <= '0';
                    Send <= '0';
                    
                    Command_Type <= TO_UNSIGNED(3,2);
                    Data_In      <= x"FFAA5533";
                    wait for CLOCK_PERIOD*100;
                    Send <= '1';
                    wait for CLOCK_PERIOD*1;
                    Send <= '0';
                    wait for CLOCK_PERIOD*1000;
                    Send <= '1';
                    wait for CLOCK_PERIOD*1;
                    Send <= '0';
                    wait;                    
        end process stimul;                 

end Behavioral;
