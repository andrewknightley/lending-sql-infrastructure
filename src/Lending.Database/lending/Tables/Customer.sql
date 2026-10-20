CREATE TABLE [lending].[Customer]
(
    [CustomerId] uniqueidentifier NOT NULL CONSTRAINT [DF_Customer_Id] DEFAULT NEWSEQUENTIALID(),
    [CustomerNumber] varchar(30) NOT NULL,
    [FirstName] nvarchar(100) NOT NULL,
    [LastName] nvarchar(100) NOT NULL,
    [DateOfBirth] date NOT NULL,
    [Email] nvarchar(254) NULL,
    [Status] varchar(20) NOT NULL CONSTRAINT [DF_Customer_Status] DEFAULT 'Active',
    [CreatedAtUtc] datetime2(7) NOT NULL CONSTRAINT [DF_Customer_Created] DEFAULT SYSUTCDATETIME(),
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_Customer] PRIMARY KEY ([CustomerId]),
    CONSTRAINT [UQ_Customer_Number] UNIQUE ([CustomerNumber]),
    CONSTRAINT [CK_Customer_Status] CHECK ([Status] IN ('Active', 'Inactive', 'Deceased'))
);


