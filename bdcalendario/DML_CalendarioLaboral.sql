-- ============================================================
-- Datos maestros de la tabla TIPO.
-- El microservicio de calendario asocia los festivos que
-- consume de la API Festivos al tipo "Día festivo".
-- ============================================================

INSERT INTO Tipo (Id, Tipo) VALUES (1, 'Día laboral');
INSERT INTO Tipo (Id, Tipo) VALUES (2, 'Fin de semana');
INSERT INTO Tipo (Id, Tipo) VALUES (3, 'Día festivo');

-- Como los INSERT anteriores usan Id explícito, la secuencia de la
-- columna no avanza. Se sincroniza para permitir crear nuevos tipos
-- desde POST /api/tipos/agregar sin conflictos de llave duplicada.
SELECT setval(
    pg_get_serial_sequence('tipo', 'id'),
    (SELECT MAX(Id) FROM Tipo)
);
