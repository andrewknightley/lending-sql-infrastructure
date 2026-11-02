CREATE TABLE [lending].[AgreementEvent]
(
    [EventId] uniqueidentifier NOT NULL,
    [CreditAgreementId] uniqueidentifier NOT NULL,
    [StreamVersion] bigint NOT NULL,
    [EventType] varchar(80) NOT NULL,
    [SchemaVersion] int NOT NULL,
    [OccurredAtUtc] datetime2(7) NOT NULL,
    [Payload] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_AgreementEvent] PRIMARY KEY ([CreditAgreementId], [StreamVersion]),
    CONSTRAINT [UQ_AgreementEvent_Id] UNIQUE ([EventId]),
    CONSTRAINT [FK_AgreementEvent_Stream] FOREIGN KEY ([CreditAgreementId]) REFERENCES [lending].[AgreementStream] ([CreditAgreementId]),
    CONSTRAINT [CK_AgreementEvent_Version] CHECK ([StreamVersion] >= 1),
    CONSTRAINT [CK_AgreementEvent_Schema] CHECK ([SchemaVersion] = 1),
    CONSTRAINT [CK_AgreementEvent_Type] CHECK ([EventType] IN ('AgreementCreated', 'AgreementActivated', 'AgreementImported')),
    CONSTRAINT [CK_AgreementEvent_Json] CHECK (ISJSON([Payload]) = 1)
);
