library ieee;
use ieee.numeric_bit.all;

------------------------------------------------------------------------------------------
-- Right-shift Register
------------------------------------------------------------------------------------------

entity registerRightShift11 is                      -- Registrador de 11 bits
    port (
        clock       : in  bit;                      -- Controle global: clock
        shift       : in  bit;                      -- Se '1' conteúdo do registrador é deslocado para a direita (síncrono)
        parallel_in : in  bit_vector(10 downto 0);  -- Entrada paralela do registrador
        serial_out  : out bit                       -- Saida serial do registrador
        );
end entity;

architecture arch of registerRightShift11 is
    signal internal : bit_vector(11 downto 0);  -- Bit extra no vetor que serve pra manter o sinal em 1 quando
                                                -- o shift está desligado e ser descartado quando shift está ligado
begin
    process(clock)
    begin
        if shift = '0' then
            internal <= parallel_in & '1';
        elsif (rising_edge(clock)) then
            internal <= '0' & internal(11 downto 1);
        end if;
    end process;
    serial_out <= internal(0);
end architecture;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--  Counter
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;

entity Counter is                       -- Contador que conta até 11 dái reseta.
    port (
        clock      : in  bit;           -- Controle global: clock
        count      : in  bit;           -- Se '1' conteúdo do registrador é incrementado de 1 (síncrono)
        count_done : out bit            -- Término da contagem
        );
end entity;

architecture arch of Counter is
    signal internal : unsigned(4 downto 0);
begin
    process(clock)
    begin
        if count = '0' then
            internal <= (others => '0');

        elsif (rising_edge(clock)) then
            internal <= internal + 1;
            if internal = 11 then
                internal <= (others => '0');

            end if;
        end if;
    end process;
    count_done <= '1' when internal = 0 else '0';
end architecture;

------------------------------------------------------------------------------------------
-- Main entity
------------------------------------------------------------------------------------------

entity uart is
    port(
        dado         : in  bit_vector(7 downto 0);
        start        : in  bit;
        TX           : out bit;
        ok           : out bit;
        clock, reset : in  bit
        );
end entity;

architecture structure of uart is
    component uart_fd is
        port (
            dado         : in  bit_vector(7 downto 0);
            TX           : out bit;
            clock        : in  bit;
            transmit_on  : in  bit;
            transmit_off : out bit);
    end component uart_fd;

    component uart_uc is
        port (
            start        : in  bit;
            ok           : out bit;
            clock, reset : in  bit;
            transmit_on  : out bit;
            transmit_off : in  bit);
    end component uart_uc;

-- sinais internos de controle
    signal transmit_on  : bit;
    signal transmit_off : bit;
    signal clock_n      : bit;

begin

    clock_n <= not(clock);              -- Clock negado para o FD
    fd : uart_fd
        port map (
            dado,
            TX,
            clock_n,
            transmit_on,
            transmit_off);

    uc : uart_uc
        port map (
            start,
            ok,
            clock,
            reset,
            transmit_on,
            transmit_off
            );

end architecture;

------------------------------------------------------------------------------------------
entity uart_fd is

    port (
        dado         : in  bit_vector(7 downto 0);
        TX           : out bit;
        clock        : in  bit;
        transmit_on  : in  bit;         -- Sinal de controle da UC: ínicio da transmissão
        transmit_off : out bit          -- Sinal de condição para UC: término da transmissão
        );

end entity uart_fd;

architecture structure of uart_fd is


    component registerRightShift11 is
        port (
            clock       : in  bit;
            shift       : in  bit;
            parallel_in : in  bit_vector(10 downto 0);
            serial_out  : out bit);
    end component registerRightShift11;

    component Counter is
        port (
            clock      : in  bit;
            count      : in  bit;
            count_done : out bit);
    end component Counter;

    signal internal : bit_vector(10 downto 0);

begin  -- architecture structure
    reg : registerRightShift11          -- Usado para transmitir o próximo bit do sinal a cada ciclo do clock.
        port map (
            clock       => clock,
            shift       => transmit_on,
            parallel_in => internal,
            serial_out  => TX);

    count : Counter                     -- Usado para determinar se a transmissão está completa.
        port map (
            clock      => clock,
            count      => transmit_on,
            count_done => transmit_off);

    internal <= "11" & dado & '0';



end architecture structure;

------------------------------------------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;


entity uart_uc is
    port(
        start        : in  bit;
        ok           : out bit;
        clock, reset : in  bit;
        transmit_on  : out bit;         -- sinal de controle para FD: inicio da transmissão
        transmit_off : in  bit          -- sinal de condição da FD: transmissão completa
        );

end entity uart_uc;

architecture fsm of uart_uc is

    ----- Código padrão para tratar os estados
    type state_t is (start_s, transmitting_s);   -- lista de estados da UC: Inicial e transmitindo
    signal next_state, current_state : state_t;  -- variáveis de estado: atual e próximo

begin
    ----- Máquina de estados padrão
    fsm : process(clock, reset)
    begin
        if reset = '1' then             -- reset assíncrono
            current_state <= start_s;
        elsif rising_edge(clock) then   -- atuazalição síncrona do estado
            current_state <= next_state;
        end if;
    end process;

    -- Lógica de próximo estado
    next_state <=
        transmitting_s when (current_state = start_s) and (start = '1')               else  -- Se está no Idle e recebeu o sinal de start, comece a transmitir.
        start_s        when (current_state = transmitting_s) and (transmit_off = '1') else  -- Se está transmitindo e recebeu o sinal de fim de transmissão, voltar pra idle.
        current_state;                                                                      --Fallback: Se nenhuma transição é válida, manter o estado atual.

    --Decodificador do estado
    ok          <= '1' when (current_state = start_s)        else '0';  -- Ok somente quando Idle.
    transmit_on <= '1' when (current_state = transmitting_s) else '0';  -- transmit_on só quando transmitindo.
end architecture;
------------------------------------------------------------------------------------------
