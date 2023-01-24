----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Javad Alishoar
-- 
-- Create Date: 01/21/2023 10:34:59 PM
-- Design Name: 
-- Module Name: SPI_Controller - Behavioral
-- Project Name: ADF4350 
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

entity SPI_Controller is
    Port ( Data_In : in unsigned (31 downto 0);
           Command_Type : in unsigned (1 downto 0);
           Send : in STD_LOGIC;
           Force_CS : in STD_LOGIC;
           Data_Out : out unsigned (7 downto 0);
           Data_Out_Valid : out STD_LOGIC;
           Busy : out STD_LOGIC;
           Clock : in STD_LOGIC;
           CS : out STD_LOGIC := '1';
           SCK : out STD_LOGIC;
           MOSI : out STD_LOGIC;
           MISO : in STD_LOGIC);
end SPI_Controller;

architecture Behavioral of SPI_Controller is
    signal  Data_In_Int         : unsigned(31 downto 0) := ( others => '0');
    signal  Data_In_Buff        : unsigned(31 downto 0) := ( others => '0');
    signal  Send_Int            : std_logic := '0';
    signal  Send_Prev           : std_logic := '0';
    signal  Command_Type_Int    : unsigned(1 downto 0)  := ( others => '0');
    signal  Force_CS_Int        : std_logic := '0';
    signal  Force_CS_Buff       : std_logic := '1';
    signal  Data_Out_Int        : unsigned(7 downto 0)  := ( others => '0');
    signal  Data_Out_Valid_Int  : std_logic := '0';
    signal  Busy_Int            : std_logic := '0';
    signal  Busy_Int_1          : std_logic := '0';
    signal  Busy_Int_2          : std_logic := '0';
    signal  MOSI_Int            : std_logic := '0';
    signal  MISO_Int            : std_logic := '0';
    signal  SCK_Int             : std_logic := '0';
    signal  CS_Int              : std_logic := '1';
    
    type    SPI_Data_Bit_Width_Array  is array(0 to 3) of unsigned(4 downto 0);
    
    signal  SPI_Data_Bit_Width  : SPI_Data_Bit_Width_Array :=   
            ( TO_UNSIGNED(7,5),
              TO_UNSIGNED(15,5),
              TO_UNSIGNED(23,5),
              TO_UNSIGNED(31,5)
              );
              
    signal  SPI_Data_Bit_Width_Buff : unsigned(4 downto 0) := ( others => '0');
    signal  SCK_Clock_Divider   : unsigned(3 downto 0) := ( others => '0' );             
    signal  SPI_Write_State     : std_logic := '0';
    signal  SCK_Disable         : std_logic := '0';
    signal  SPI_Transmission_End    : std_logic := '0';
    signal  SPI_Opcode_Byte         : std_logic := '0';
    signal  Set_SCK_Disable         : std_logic := '0';
    signal  CS_Disable_Counter      : unsigned(2 downto 0) := ( others => '0');
    signal  SPI_Data_Out_Bit_Width  : unsigned(2 downto 0) := ( others => '0');
                   
begin
    Data_Out <= Data_Out_Int;
    Data_Out_Valid <= Data_Out_Valid_Int;
    Busy <= Busy_Int or Busy_Int_1 or Busy_Int_2 ;
    MOSI <= MOSI_Int;
    SCK  <= SCK_Int and SCK_Disable;
    CS   <= CS_Int and Force_CS_Buff  ; 
   
        
    process ( Clock)
        begin
            if rising_edge ( Clock) then 
                Data_In_Int <= Data_In;
                Send_Int <= Send;
                Send_Prev <= Send_Int;
                Command_Type_Int <= Command_Type;
                Force_CS_Int <= Force_CS;
                MISO_Int <= MISO;
                --CS_Int <= '0';     -- Remove code  from main program
                SCK_Int <= '1';
                SCK_Clock_Divider <= SCK_Clock_Divider + 1;
                Data_Out_Valid_Int <= '0';
                Busy_Int_1 <= Busy_Int;
                Busy_Int_2 <= Busy_Int_1;
                -- Time setup time 
                if( CS_Disable_Counter < TO_UNSIGNED(1,3) ) then
                    CS_Disable_Counter <= CS_Disable_Counter + 1;
                    CS_Int <= '0';
                end if;
                -- Cerate CLOCK SPI 
                if( SCK_Clock_Divider = TO_UNSIGNED(0,4) and SPI_Write_State = '1' and CS_Int = '0') then
                    --CS_Int <= '0';
                    MOSI_Int <= Data_In_Buff( TO_INTEGER(SPI_Data_Bit_Width_Buff));
                    SPI_Data_Bit_Width_Buff <= SPI_Data_Bit_Width_Buff - 1;
                    SCK_Disable <= Set_Sck_Disable;
                    
                    if(SPI_Data_Bit_Width_Buff = TO_UNSIGNED(0,5)) then
                        SPI_Transmission_End  <= '1' ;
                    end if;
                    
                    if( SPI_Transmission_End = '1' ) then
                        SPI_Transmission_End <= '0';
                        SCK_Disable <= '0';
                        Busy_Int <= '0';
                        Set_SCk_Disable  <= '0';
                        SPI_Write_State <= '0'; 
                        MOSI_Int <= '0';  
                    end if;
                    
                end if;
                --  Read data after write command
                if(SCK_Clock_Divider = TO_UNSIGNED(9,4) and SCK_Disable = '1') then
                    Data_Out_Int( TO_INTEGER(SPI_Data_Out_Bit_Width)) <= MISO_Int;
                    SPI_Data_Out_Bit_Width <= SPI_Data_Out_Bit_Width - 1;
                    
                    if( SPI_Data_Out_Bit_Width = TO_UNSIGNED(0,3)) then
                        Data_Out_Valid_Int <= SPI_Opcode_Byte or (not Force_CS_Buff);
                        SPI_Opcode_Byte <= '1';
                    end if;
                end if;
               
               if( SCK_Clock_Divider < TO_UNSIGNED(5,4)) then
                    SCK_Int <= '0';                     
               end if;
               
               if( SCK_Clock_Divider = TO_UNSIGNED(9,4)) then
                    SCK_Clock_Divider <= ( others => '0');
               end if;
               -- Intialize Program
               if( Send_Int = '1' and Send_Prev = '0' and Busy_Int = '0') then
                    Data_In_Buff <= Data_In_Int ;
                    Force_CS_Buff <= Force_CS_Int;
                    SPI_Data_Bit_Width_Buff <= SPI_Data_Bit_Width( TO_INTEGER(Command_Type));
                    SPI_Data_Out_Bit_Width <= TO_UNSIGNED(7,3);
                    CS_Disable_Counter <= ( others => '0');
                    SCK_Clock_Divider <= TO_UNSIGNED(6,4);
                    SPI_Write_State <= '1';
                    SPI_Opcode_Byte <= '0';
                    Busy_Int <= '1';
                    Set_SCK_Disable <= '1';
                    SPI_Transmission_End <= '0';
                    SCK_Disable <= '0';
               end if;
               --- Add code to main program
               if( Busy_Int = '0' and Busy_Int_1 = '0' ) then
                    CS_Int <= '1';   
               end if;
            end if;
    end process;
end Behavioral;
