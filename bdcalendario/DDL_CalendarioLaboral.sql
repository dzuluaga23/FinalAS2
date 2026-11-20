-- ============================================================
-- Script de inicialización para el contenedor PostgreSQL.
-- Se ejecuta automáticamente dentro de la base de datos
-- "calendariolaboral" creada por la imagen (POSTGRES_DB).
-- No incluye CREATE DATABASE porque Docker ya la crea.
-- ============================================================

-- Crear la tabla TIPO
CREATE TABLE Tipo (
    Id SERIAL PRIMARY KEY,
    Tipo VARCHAR(100) NOT NULL
);

-- Crear índice para TIPO
CREATE UNIQUE INDEX ixTipo ON Tipo (Tipo);

-- Crear la tabla CALENDARIO
CREATE TABLE Calendario (
    Id SERIAL PRIMARY KEY,
    Fecha DATE NOT NULL,
    IdTipo INT NOT NULL,
    CONSTRAINT fkCalendario_Tipo FOREIGN KEY (IdTipo) REFERENCES Tipo (Id),
    Descripcion VARCHAR(100) NULL
);

-- Crear índice para CALENDARIO ordenado por FECHA
CREATE UNIQUE INDEX ixCalendario ON Calendario (Fecha);
