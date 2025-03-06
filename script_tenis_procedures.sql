
/* Paso 5.2  Sin probar*/
CREATE OR REPLACE PROCEDURE TEST_PROCEDURES_TENIS IS
BEGIN
    -- Prueba de pReservarPista
    BEGIN
        pReservarPista('Socio 1', CURRENT_DATE, 12);
        DBMS_OUTPUT.PUT_LINE('Reserva 1: OK');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Reserva 1: MAL - ' || SQLERRM);
    END;
    -- Prueba de pAnularReserva
    BEGIN
        pAnularReserva('Socio 1', CURRENT_DATE, 12, 1);
        DBMS_OUTPUT.PUT_LINE('Anulación 1: OK');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Anulación 1: MAL - ' || SQLERRM);
    END;
END;
/
/* Paso 5.1 Sin probar*/

CREATE OR REPLACE PROCEDURE pAnularReserva(
    p_socio VARCHAR,
    p_fecha DATE,
    p_hora INTEGER,
    p_pista INTEGER
) IS
    v_rows_deleted INTEGER;
BEGIN
    DELETE FROM reservas
    WHERE trunc(fecha) = trunc(p_fecha)
      AND pista = p_pista
      AND hora = p_hora
      AND socio = p_socio;

    v_rows_deleted := SQL%ROWCOUNT;

    IF v_rows_deleted = 0 THEN
        raise_application_error(-20000, 'Reserva inexistente');
    END IF;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        raise_application_error(-20999, 'Error en pAnularReserva: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE pReservarPista(
    p_socio VARCHAR,
    p_fecha DATE,
    p_hora INTEGER
) IS

    CURSOR vPistasLibres IS
        SELECT nro
        FROM pistas
        WHERE nro NOT IN (
            SELECT pista
            FROM reservas
            WHERE trunc(fecha) = trunc(p_fecha)
              AND hora = p_hora
        )
        ORDER BY nro;

    vPista INTEGER;
    vReservaExistente INTEGER;

BEGIN
    -- Verificar si la reserva ya existe
    SELECT COUNT(*) INTO vReservaExistente
    FROM reservas
    WHERE trunc(fecha) = trunc(p_fecha)
      AND hora = p_hora
      AND socio = p_socio;

    IF vReservaExistente > 0 THEN
        raise_application_error(-20001, 'No quedan pistas libres en esa fecha y hora');
    END IF;

    OPEN vPistasLibres;
    FETCH vPistasLibres INTO vPista;

    IF vPistasLibres%NOTFOUND THEN
        CLOSE vPistasLibres;
        raise_application_error(-20001, 'No quedan pistas libres en esa fecha y hora');
    END IF;

    INSERT INTO reservas VALUES (vPista, p_fecha, p_hora, p_socio);
    CLOSE vPistasLibres;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        raise_application_error(-20999, 'Error en pReservarPista: ' || SQLERRM);
END;
/
