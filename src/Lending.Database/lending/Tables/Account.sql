CREATE TABLE [lending].[Account]
(
    [AccountId] uniqueidentifier NOT NULL CONSTRAINT [DF_Account_Id] DEFAULT NEWSEQUENTIALID(),
    [CustomerId] uniqueidentifier NOT NULL,
    [AccountNumber] varchar(30) NOT NULL,
    [CurrencyCode] char(3) NOT NULL CONSTRAINT [DF_Account_Currency] DEFAULT 'GBP',
    [Status] varchar(20) NOT NULL CONSTRAINT [DF_Account_Status] DEFAULT 'Open',
    [OpenedAtUtc] datetime2(7) NOT NULL CONSTRAINT [DF_Account_Opened] DEFAULT SYSUTCDATETIME(),
    [ClosedAtUtc] datetime2(7) NULL,
    [RowVersion] rowversion NOT NULL,
    CONSTRAINT [PK_Account] PRIMARY KEY ([AccountId]),
    CONSTRAINT [UQ_Account_Number] UNIQUE ([AccountNumber]),
    CONSTRAINT [FK_Account_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [lending].[Customer] ([CustomerId]),
    CONSTRAINT [CK_Account_Currency] CHECK ([CurrencyCode] = 'GBP'),
    CONSTRAINT [CK_Account_Status] CHECK ([Status] IN ('Open', 'Suspended', 'Closed')),
    CONSTRAINT [CK_Account_Closure] CHECK
    (
        ([Status] = 'Closed' AND [ClosedAtUtc] IS NOT NULL AND [ClosedAtUtc] >= [OpenedAtUtc])
        OR ([Status] IN ('Open', 'Suspended') AND [ClosedAtUtc] IS NULL)
    )
);
