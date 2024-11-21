CREATE TABLE aktuallVersion (
    versionNumber INT PRIMARY KEY
);
INSERT INTO aktuallVersion VALUES (0);

CREATE TABLE versions (
    -- inregistrare fiecare modif; param - pt stocarea parametrilor
    versionId INT IDENTITY(1,1) PRIMARY KEY, 
    FunctionName VARCHAR(100),  
    Param1 VARCHAR(MAX) DEFAULT NULL,
    Param2 VARCHAR(MAX) DEFAULT NULL,
    Param3 VARCHAR(MAX) DEFAULT NULL,
    Param4 VARCHAR(MAX) DEFAULT NULL
);
GO

CREATE PROCEDURE changeColumnType(
    @tableName varchar(50),
    @columnName varchar(50),
    @newDataType varchar(50)
)
AS
BEGIN
    DECLARE @sqlQuery AS varchar(MAX);
    DECLARE @oldDataType NVARCHAR(50);
    -- pt stocarea tipului de date anterior 

    -- Obtinere tip de date anterior pt rollback 
    SELECT @oldDataType = DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = @tableName AND COLUMN_NAME = @columnName;

    -- Incrementare versiune
    UPDATE aktuallVersion SET versionNumber = versionNumber + 1;

    -- Salvare versiune
    INSERT INTO versions (FunctionName, Param1, Param2, Param3, Param4)
    VALUES ('changeColumnType', @tableName, @columnName, @newDataType, @oldDataType);

    -- Modificare coloana
    SET @sqlQuery = 'ALTER TABLE ' + @tableName + ' ALTER COLUMN ' + @columnName + ' ' + @newDataType;
    EXECUTE (@sqlQuery);
END;
GO

-- revenim la tipul de date anterior 
CREATE PROCEDURE rollbackchangeColumnType(
    @tableName varchar(50),
    @columnName varchar(50),
    @newDataType varchar(50)
)
AS
BEGIN
    DECLARE @sqlQuery AS varchar(MAX);

    -- Decrementarea versiunii
    UPDATE aktuallVersion SET versionNumber = versionNumber - 1;

    -- Revenim la tipul de date anterior 
    SET @sqlQuery = 'ALTER TABLE ' + @tableName + ' ALTER COLUMN ' + @columnName + ' ' + @newDataType;
    EXECUTE (@sqlQuery);
END;
GO

CREATE PROCEDURE addDefaultConstraintToColumn(
    @tableName varchar(50),
    @columnName varchar(50),
    @defaultConstraint varchar(MAX)
)
AS
BEGIN
    DECLARE @sqlQuery AS varchar(MAX);

    IF EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tableName AND COLUMN_NAME = @columnName
    )
    BEGIN
        UPDATE aktuallVersion SET versionNumber = versionNumber + 1;

        INSERT INTO versions (FunctionName, Param1, Param2, Param3)
        VALUES ('addDefaultConstraintToColumn', @tableName, @columnName, @defaultConstraint);

        IF DATALENGTH(@defaultConstraint) IS NOT NULL
        BEGIN
            SET @defaultConstraint = '''' + REPLACE(@defaultConstraint, '''', '''''') + '''';
        END

        SET @sqlQuery = 'ALTER TABLE ' + @tableName + ' ADD CONSTRAINT DF_' + @columnName + ' DEFAULT ' + @defaultConstraint + ' FOR ' + @columnName;
        EXECUTE (@sqlQuery);
    END
    ELSE 
    BEGIN 
        PRINT 'Column does not exist';
    END
END;
GO

CREATE PROCEDURE rollBackaddDefaultConstraintToColumn(
    @tableName varchar(50),
    @columnName varchar(50)
)
AS
BEGIN
    DECLARE @sqlQuery AS varchar(MAX);

    IF EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tableName AND COLUMN_NAME = @columnName
    )
    BEGIN
        UPDATE aktuallVersion SET versionNumber = versionNumber - 1;

        SET @sqlQuery = 'ALTER TABLE ' + @tableName + ' DROP CONSTRAINT DF_' + @columnName;
        EXECUTE (@sqlQuery);
    END
    ELSE 
    BEGIN 
        PRINT 'Column does not exist';
    END
END;
GO

CREATE PROCEDURE createTable(
    @tableName varchar(50),
    @columnDefinitions varchar(MAX),
    @primaryKeyColumnName varchar(50)
)
AS
BEGIN
    DECLARE @sqlQuery AS varchar(MAX);
    
    UPDATE aktuallVersion SET versionNumber = versionNumber + 1;

    INSERT INTO versions (FunctionName, Param1, Param2, Param3)
    VALUES ('createTable', @tableName, @columnDefinitions, @primaryKeyColumnName);

    SET @sqlQuery = 'CREATE TABLE ' + @tableName + ' (' + @columnDefinitions + ', PRIMARY KEY (' + @primaryKeyColumnName + '))';
    EXECUTE (@sqlQuery);
END;
GO

CREATE PROCEDURE rollBackCreateTable(
    @tableName varchar(50)
)
AS
BEGIN
    DECLARE @sqlQuery AS varchar(MAX);

    UPDATE aktuallVersion SET versionNumber = versionNumber - 1;

    SET @sqlQuery = 'DROP TABLE IF EXISTS ' + @tableName;
    EXECUTE (@sqlQuery);
END;
GO

CREATE PROCEDURE addColumnToTable(
    @tableName varchar(50),
    @columnName varchar(50),
    @columnDataType varchar(50)
)
AS
BEGIN
    DECLARE @sqlQuery AS varchar(MAX);

    UPDATE aktuallVersion SET versionNumber = versionNumber + 1;

    INSERT INTO versions (FunctionName, Param1, Param2, Param3)
    VALUES ('addColumnToTable', @tableName, @columnName, @columnDataType);

    SET @sqlQuery = 'ALTER TABLE ' + @tableName + ' ADD ' + @columnName + ' ' + @columnDataType;
    EXECUTE (@sqlQuery);
END;
GO

CREATE PROCEDURE rollBackaddColumnToTable(
    @tableName varchar(50),
    @columnName varchar(50)
)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME = @columnName)
    BEGIN
        DECLARE @sqlQuery AS varchar(MAX);

        UPDATE aktuallVersion SET versionNumber = versionNumber - 1;

        SET @sqlQuery = 'ALTER TABLE ' + @tableName + ' DROP COLUMN ' + @columnName;
        EXECUTE (@sqlQuery);
    END
    ELSE
    BEGIN
        PRINT 'Column does not exist';
    END
END;
GO

CREATE PROCEDURE addForeignKeyConstraint(
    @tableName varchar(50), 
    @columnName varchar(50),
    @referencedTable varchar(50),
    @referencedColumn varchar(50)
)
AS
BEGIN
    DECLARE @sqlQuery AS varchar(MAX);

    UPDATE aktuallVersion SET versionNumber = versionNumber + 1;

    INSERT INTO versions (FunctionName, Param1, Param2, Param3, Param4)
    VALUES ('addForeignKeyConstraint', @tableName, @columnName, @referencedTable, @referencedColumn);

    SET @sqlQuery = 'ALTER TABLE ' + @tableName + ' ADD CONSTRAINT FK_' + @columnName + '_' + @referencedTable +
                    ' FOREIGN KEY (' + @columnName + ') REFERENCES ' + @referencedTable + '(' + @referencedColumn + ')';
    EXECUTE (@sqlQuery);
END;
GO

CREATE PROCEDURE rollBackaddForeignKeyConstraint(
    @tableName varchar(50),
    @constraintName varchar(100),
    @referencedTableName varchar(100)
)
AS
BEGIN
    DECLARE @sqlQuery AS varchar(MAX);

    IF EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @tableName
    )
    BEGIN
        UPDATE aktuallVersion SET versionNumber = versionNumber - 1;

        SET @sqlQuery = 'ALTER TABLE ' + @tableName + ' DROP CONSTRAINT FK_' + @constraintName + '_' + @referencedTableName;
        EXECUTE (@sqlQuery);
    END
    ELSE 
    BEGIN 
        PRINT 'Table does not exist';
    END
END;
GO

-- Test createTable 
EXEC createTable 'TestTable', 'ID INT, Column1 INT, Column2 VARCHAR(50)', 'ID';

-- Test addColumnToTable + rollback
EXEC addColumnToTable 'TestTable', 'Column3', 'REAL';
EXEC rollBackaddColumnToTable 'TestTable', 'Column3';

-- Test  addDefaultConstraintToColumn + rollback
EXEC addDefaultConstraintToColumn 'TestTable', 'Column2', 'DefaultValue';
EXEC rollBackaddDefaultConstraintToColumn 'TestTable', 'Column2';

-- Test  changeColumnType + rollback
EXEC changeColumnType 'TestTable', 'Column2', 'TEXT';
EXEC rollbackchangeColumnType 'TestTable', 'Column2', 'VARCHAR(50)';

-- Creare tabel de referinta pt testarea FK
EXEC createTable 'ReferenceTable', 'RefID INT', 'RefID';

-- Test addForeignKeyConstraint + rollback
EXEC addColumnToTable 'TestTable', 'RefID', 'INT';
EXEC addForeignKeyConstraint 'TestTable', 'RefID', 'ReferenceTable', 'RefID';
EXEC rollBackaddForeignKeyConstraint 'TestTable', 'RefID', 'ReferenceTable';

-- Rollback pt a sterge tabelele de test
EXEC rollBackCreateTable 'TestTable';
EXEC rollBackCreateTable 'ReferenceTable';
GO


-- part 2
-- mergem la versiunea dorita
CREATE PROCEDURE universalRollbackToVersion
    @targetVersion INT
AS
BEGIN
    DECLARE @currentVersion INT;
    SELECT @currentVersion = versionNumber FROM aktuallVersion;

    WHILE @currentVersion <> @targetVersion
    BEGIN
        DECLARE @functionName VARCHAR(100),
                @tableName NVARCHAR(255),
                @param1 NVARCHAR(255),
                @param2 NVARCHAR(255),
                @param3 NVARCHAR(255);

        IF @currentVersion > @targetVersion
        BEGIN
            SELECT TOP 1
                @functionName = FunctionName,
                @tableName = Param1,
                @param1 = Param2,
                @param2 = Param3,
                @param3 = Param4
            FROM versions
            WHERE versionId = @currentVersion;

            IF @functionName = 'addDefaultConstraintToColumn'
            BEGIN
                EXEC rollBackaddDefaultConstraintToColumn @tableName, @param1;
            END
            ELSE IF @functionName = 'createTable'
            BEGIN
                EXEC rollBackCreateTable @tableName;
            END
            ELSE IF @functionName = 'addColumnToTable'
            BEGIN
                EXEC rollBackaddColumnToTable @tableName, @param1;
            END
            ELSE IF @functionName = 'changeColumnType'
            BEGIN
                EXEC rollbackchangeColumnType @tableName, @param1, @param3;
            END
            ELSE IF @functionName = 'addForeignKeyConstraint'
            BEGIN
                EXEC rollBackaddForeignKeyConstraint @tableName, @param1, @param2;
            END

            SET @currentVersion = @currentVersion - 1;
            UPDATE aktuallVersion SET versionNumber = @currentVersion;
        END
        ELSE IF @currentVersion < @targetVersion
        BEGIN
            SELECT TOP 1
                @functionName = FunctionName,
                @tableName = Param1,
                @param1 = Param2,
                @param2 = Param3,
                @param3 = Param4
            FROM versions
            WHERE versionId = @currentVersion + 1;

            IF @functionName = 'addDefaultConstraintToColumn'
            BEGIN
                EXEC addDefaultConstraintToColumn @tableName, @param1, @param2;
            END
            ELSE IF @functionName = 'createTable'
            BEGIN
                EXEC createTable @tableName, @param1, @param2;
            END
            ELSE IF @functionName = 'addColumnToTable'
            BEGIN
                EXEC addColumnToTable @tableName, @param1, @param2;
            END
            ELSE IF @functionName = 'changeColumnType'
            BEGIN
                EXEC changeColumnType @tableName, @param1, @param2;
            END
            ELSE IF @functionName = 'addForeignKeyConstraint'
            BEGIN
                EXEC addForeignKeyConstraint @tableName, @param1, @param2, @param3;
            END

            SET @currentVersion = @currentVersion + 1;
            UPDATE aktuallVersion SET versionNumber = @currentVersion;
        END
    END
END;
GO

-- Test createTable 
EXEC createTable 'Test2', 'ID INT', 'ID';

-- Test addColumnToTable + rollback prin universalRollbackToVersion
EXEC addColumnToTable 'Test', 'Name', 'Varchar(10)';
EXEC universalRollbackToVersion 1; -- rollback pentru a elimina "Column3"

-- Test addDefaultConstraintToColumn + rollback prin universalRollbackToVersion
EXEC addDefaultConstraintToColumn 'TestTable', 'Column2', 'DefaultValue';
EXEC universalRollbackToVersion 1; 

-- Test changeColumnType + rollback prin universalRollbackToVersion
EXEC changeColumnType 'Test', 'Name', 'Varchar(30)';
EXEC universalRollbackToVersion 2; 

-- Creare tabel pt testarea cheii externe
EXEC createTable 'ReferenceTable', 'RefID INT', 'RefID';

-- Test addForeignKeyConstraint + rollback prin universalRollbackToVersion
EXEC addColumnToTable 'TestTable', 'RefID', 'INT';
EXEC addForeignKeyConstraint 'TestTable', 'RefID', 'ReferenceTable', 'RefID';
EXEC universalRollbackToVersion 4; -- rollback pentru a elimina cheia externa si coloana "RefID"

-- Rollback complet 
EXEC universalRollbackToVersion 2;

DROP PROCEDURE IF EXISTS changeColumnType;
DROP PROCEDURE IF EXISTS rollbackchangeColumnType;
DROP PROCEDURE IF EXISTS addDefaultConstraintToColumn;
DROP PROCEDURE IF EXISTS rollBackaddDefaultConstraintToColumn;
DROP PROCEDURE IF EXISTS createTable;
DROP PROCEDURE IF EXISTS rollBackCreateTable;
DROP PROCEDURE IF EXISTS addColumnToTable;
DROP PROCEDURE IF EXISTS rollBackaddColumnToTable;
DROP PROCEDURE IF EXISTS addForeignKeyConstraint;
DROP PROCEDURE IF EXISTS rollBackaddForeignKeyConstraint;
DROP PROCEDURE IF EXISTS universalRollbackToVersion;
DROP TABLE aktuallVersion;
DROP TABLE versions;
DROP TABLE TestTable;
DROP TABLE Test2;

SELECT *
FROM versions

SELECT *
FROM aktuallVersion

DROP TABLE TestTable
DROP TABLE versions
DROP TABLE aktuallVersion