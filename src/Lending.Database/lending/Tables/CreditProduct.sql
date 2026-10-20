CREATE TABLE [lending].[CreditProduct]
(
    [CreditProductId] uniqueidentifier NOT NULL CONSTRAINT [DF_CreditProduct_Id] DEFAULT NEWSEQUENTIALID(),
    [ProductCode] varchar(30) NOT NULL,
    [ProductName] nvarchar(150) NOT NULL,
    [ProductType] varchar(20) NOT NULL,
    [IsAvailable] bit NOT NULL CONSTRAINT [DF_CreditProduct_Available] DEFAULT 1,
    [CreatedAtUtc] datetime2(7) NOT NULL CONSTRAINT [DF_CreditProduct_Created] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_CreditProduct] PRIMARY KEY ([CreditProductId]),
    CONSTRAINT [UQ_CreditProduct_Code] UNIQUE ([ProductCode]),
    CONSTRAINT [CK_CreditProduct_Type] CHECK ([ProductType] IN ('FixedLoan', 'RevolvingCredit'))
);
