-- SISTEMA DE ADOPCION DE ANIMALES - SQL SERVER


USE master;
GO

IF DB_ID(N'adopcion_animales_mejorada') IS NULL
BEGIN
    CREATE DATABASE adopcion_animales_mejorada;
END;
GO

USE adopcion_animales_mejorada;
GO

-- Para volver a ejecutar este script en la misma base, elimina primero
-- las tablas existentes en orden de dependencias o usa una base vacia.

-- 1. Usuarios
IF OBJECT_ID(N'dbo.usuarios', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.usuarios (
        id_usuario BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        nombre NVARCHAR(100) NOT NULL,
        correo NVARCHAR(254) NOT NULL UNIQUE,
        password_hash NVARCHAR(255) NOT NULL,
        telefono NVARCHAR(25) NULL,
        direccion NVARCHAR(180) NULL,
        rol NVARCHAR(30) NOT NULL CONSTRAINT DF_usuarios_rol DEFAULT N'adoptante',
        estado NVARCHAR(20) NOT NULL CONSTRAINT DF_usuarios_estado DEFAULT N'activo',
        fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_usuarios_fecha DEFAULT SYSDATETIME(),
        fecha_actualizacion DATETIME2 NOT NULL CONSTRAINT DF_usuarios_actualizacion DEFAULT SYSDATETIME(),
        CONSTRAINT CK_usuarios_rol CHECK (rol IN (N'adoptante', N'representante_refugio', N'administrador')),
        CONSTRAINT CK_usuarios_estado CHECK (estado IN (N'activo', N'inactivo', N'bloqueado'))
    );
END;
GO

-- 2. Refugios
IF OBJECT_ID(N'dbo.refugios', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.refugios (
        id_refugio BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        id_usuario BIGINT NOT NULL UNIQUE,
        nombre NVARCHAR(120) NOT NULL,
        direccion NVARCHAR(180) NOT NULL,
        telefono NVARCHAR(25) NULL,
        correo NVARCHAR(254) NULL,
        descripcion NVARCHAR(MAX) NULL,
        estado NVARCHAR(20) NOT NULL CONSTRAINT DF_refugios_estado DEFAULT N'pendiente',
        fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_refugios_fecha DEFAULT SYSDATETIME(),
        CONSTRAINT CK_refugios_estado CHECK (estado IN (N'pendiente', N'verificado', N'suspendido')),
        CONSTRAINT FK_refugios_usuarios FOREIGN KEY (id_usuario)
            REFERENCES dbo.usuarios(id_usuario)
    );
END;
GO

-- 3. Animales
IF OBJECT_ID(N'dbo.animales', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.animales (
        id_animal BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        id_refugio BIGINT NOT NULL,
        nombre NVARCHAR(70) NOT NULL,
        especie NVARCHAR(30) NOT NULL CONSTRAINT DF_animales_especie DEFAULT N'otro',
        raza NVARCHAR(80) NULL,
        sexo NVARCHAR(20) NOT NULL CONSTRAINT DF_animales_sexo DEFAULT N'desconocido',
        fecha_nacimiento DATE NULL,
        edad_aproximada_meses SMALLINT NULL,
        tamano NVARCHAR(30) NOT NULL CONSTRAINT DF_animales_tamano DEFAULT N'no_especificado',
        descripcion NVARCHAR(MAX) NULL,
        estado NVARCHAR(30) NOT NULL CONSTRAINT DF_animales_estado DEFAULT N'disponible',
        ubicacion NVARCHAR(180) NULL,
        foto_url NVARCHAR(2048) NULL,
        esterilizado BIT NOT NULL CONSTRAINT DF_animales_esterilizado DEFAULT 0,
        vacunado BIT NOT NULL CONSTRAINT DF_animales_vacunado DEFAULT 0,
        fecha_registro DATETIME2 NOT NULL CONSTRAINT DF_animales_fecha DEFAULT SYSDATETIME(),
        fecha_actualizacion DATETIME2 NOT NULL CONSTRAINT DF_animales_actualizacion DEFAULT SYSDATETIME(),
        CONSTRAINT CK_animales_especie CHECK (especie IN (N'perro', N'gato', N'conejo', N'ave', N'otro')),
        CONSTRAINT CK_animales_sexo CHECK (sexo IN (N'macho', N'hembra', N'desconocido')),
        CONSTRAINT CK_animales_tamano CHECK (tamano IN (N'pequeno', N'mediano', N'grande', N'no_especificado')),
        CONSTRAINT CK_animales_estado CHECK (estado IN (N'disponible', N'en_proceso', N'adoptado', N'en_tratamiento', N'no_disponible')),
        CONSTRAINT CK_animales_edad CHECK (edad_aproximada_meses IS NULL OR edad_aproximada_meses >= 0),
        CONSTRAINT FK_animales_refugios FOREIGN KEY (id_refugio)
            REFERENCES dbo.refugios(id_refugio)
    );
END;
GO

-- 4. Solicitudes de adopcion
IF OBJECT_ID(N'dbo.solicitudes_adopcion', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.solicitudes_adopcion (
        id_solicitud BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        id_usuario BIGINT NOT NULL,
        id_animal BIGINT NOT NULL,
        fecha_solicitud DATETIME2 NOT NULL CONSTRAINT DF_solicitudes_fecha DEFAULT SYSDATETIME(),
        estado NVARCHAR(20) NOT NULL CONSTRAINT DF_solicitudes_estado DEFAULT N'pendiente',
        mensaje_inicial NVARCHAR(MAX) NULL,
        fecha_respuesta DATETIME2 NULL,
        observaciones NVARCHAR(MAX) NULL,
        fecha_actualizacion DATETIME2 NOT NULL CONSTRAINT DF_solicitudes_actualizacion DEFAULT SYSDATETIME(),
        CONSTRAINT CK_solicitudes_estado CHECK (estado IN (N'pendiente', N'en_revision', N'aprobada', N'rechazada', N'cancelada', N'completada')),
        CONSTRAINT FK_solicitudes_usuarios FOREIGN KEY (id_usuario)
            REFERENCES dbo.usuarios(id_usuario),
        CONSTRAINT FK_solicitudes_animales FOREIGN KEY (id_animal)
            REFERENCES dbo.animales(id_animal)
    );
END;
GO

-- 5. Mensajes
IF OBJECT_ID(N'dbo.mensajes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.mensajes (
        id_mensaje BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        id_solicitud BIGINT NOT NULL,
        id_usuario_remitente BIGINT NOT NULL,
        contenido NVARCHAR(MAX) NOT NULL,
        fecha_envio DATETIME2 NOT NULL CONSTRAINT DF_mensajes_fecha DEFAULT SYSDATETIME(),
        leido BIT NOT NULL CONSTRAINT DF_mensajes_leido DEFAULT 0,
        CONSTRAINT FK_mensajes_solicitudes FOREIGN KEY (id_solicitud)
            REFERENCES dbo.solicitudes_adopcion(id_solicitud) ON DELETE CASCADE,
        CONSTRAINT FK_mensajes_usuarios FOREIGN KEY (id_usuario_remitente)
            REFERENCES dbo.usuarios(id_usuario)
    );
END;
GO

-- 6. Fotos adicionales de animales
IF OBJECT_ID(N'dbo.fotos_animales', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.fotos_animales (
        id_foto BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        id_animal BIGINT NOT NULL,
        url NVARCHAR(2048) NOT NULL,
        texto_alternativo NVARCHAR(200) NULL,
        es_principal BIT NOT NULL CONSTRAINT DF_fotos_principal DEFAULT 0,
        fecha_subida DATETIME2 NOT NULL CONSTRAINT DF_fotos_fecha DEFAULT SYSDATETIME(),
        CONSTRAINT FK_fotos_animales FOREIGN KEY (id_animal)
            REFERENCES dbo.animales(id_animal) ON DELETE CASCADE
    );
END;
GO

-- 7. Historial de estados de solicitudes
IF OBJECT_ID(N'dbo.historial_solicitudes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.historial_solicitudes (
        id_historial BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        id_solicitud BIGINT NOT NULL,
        id_usuario_responsable BIGINT NULL,
        estado_anterior NVARCHAR(30) NULL,
        estado_nuevo NVARCHAR(30) NOT NULL,
        comentario NVARCHAR(500) NULL,
        fecha_cambio DATETIME2 NOT NULL CONSTRAINT DF_historial_fecha DEFAULT SYSDATETIME(),
        CONSTRAINT FK_historial_solicitudes FOREIGN KEY (id_solicitud)
            REFERENCES dbo.solicitudes_adopcion(id_solicitud) ON DELETE CASCADE,
        CONSTRAINT FK_historial_usuarios FOREIGN KEY (id_usuario_responsable)
            REFERENCES dbo.usuarios(id_usuario) ON DELETE SET NULL
    );
END;
GO

-- Verificar las tablas creadas
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO

-- Verificar las claves foraneas
SELECT
    OBJECT_NAME(fkc.parent_object_id) AS tabla,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS columna,
    OBJECT_NAME(fkc.referenced_object_id) AS tabla_referenciada,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS columna_referenciada
FROM sys.foreign_key_columns AS fkc
ORDER BY tabla, columna;
GO
