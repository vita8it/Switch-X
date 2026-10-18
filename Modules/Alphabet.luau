local Bit32 = bit32
local BXor = Bit32.bxor
local BAnd = Bit32.band
local RShift = Bit32.rshift
local LRotate = Bit32.lrotate

local Prefix = "NIGHTHUB|"
local BaseAlphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local WordMod = 4294967296
local Constants = { 1634760805, 857760878, 2036477234, 1797285236 }

local function ParseKey(KeyHex)
    if type(KeyHex) ~= "string" or #KeyHex ~= 64 or not KeyHex:match("^%x+$") then
        return nil, "Secret must be a 64-character hexadecimal key"
    end

    local Key = {}

    for Index = 1, #KeyHex, 2 do
        Key[#Key + 1] = tonumber(KeyHex:sub(Index, Index + 1), 16)
    end

    return Key
end

local function ReadWord(Bytes, Offset)
    return (Bytes[Offset] or 0)
        + (Bytes[Offset + 1] or 0) * 256
        + (Bytes[Offset + 2] or 0) * 65536
        + (Bytes[Offset + 3] or 0) * 16777216
end

local function WriteWord(Value)
    return {
        BAnd(Value, 255),
        BAnd(RShift(Value, 8), 255),
        BAnd(RShift(Value, 16), 255),
        BAnd(RShift(Value, 24), 255),
    }
end

local function CreateState(Key, Counter, Nonce)
    return {
        Constants[1],
        Constants[2],
        Constants[3],
        Constants[4],

        ReadWord(Key, 1),
        ReadWord(Key, 5),
        ReadWord(Key, 9),
        ReadWord(Key, 13),
        ReadWord(Key, 17),
        ReadWord(Key, 21),
        ReadWord(Key, 25),
        ReadWord(Key, 29),

        Counter % WordMod,
        ReadWord(Nonce, 1),
        ReadWord(Nonce, 5),
        ReadWord(Nonce, 9),
    }
end

local function QuarterRound(State, A, B, C, D)
    State[A] = (State[A] + State[B]) % WordMod
    State[D] = LRotate(BXor(State[D], State[A]), 16)

    State[C] = (State[C] + State[D]) % WordMod
    State[B] = LRotate(BXor(State[B], State[C]), 12)

    State[A] = (State[A] + State[B]) % WordMod
    State[D] = LRotate(BXor(State[D], State[A]), 8)

    State[C] = (State[C] + State[D]) % WordMod
    State[B] = LRotate(BXor(State[B], State[C]), 7)
end

local function Rounds(State)
    for _ = 1, 10 do
        QuarterRound(State, 1, 5, 9, 13)
        QuarterRound(State, 2, 6, 10, 14)
        QuarterRound(State, 3, 7, 11, 15)
        QuarterRound(State, 4, 8, 12, 16)

        QuarterRound(State, 1, 6, 11, 16)
        QuarterRound(State, 2, 7, 12, 13)
        QuarterRound(State, 3, 8, 9, 14)
        QuarterRound(State, 4, 5, 10, 15)
    end
end

local function GenerateBlock(Key, Nonce, Counter)
    local State = CreateState(Key, Counter, Nonce)
    local Original = table.clone(State)

    Rounds(State)

    local Output = {}

    for Index = 1, 16 do
        local Bytes = WriteWord((State[Index] + Original[Index]) % WordMod)

        for ByteIndex = 1, 4 do
            Output[(Index - 1) * 4 + ByteIndex] = Bytes[ByteIndex]
        end
    end

    return Output
end

local function GenerateStream(Key, Nonce, Counter, Length)
    local Output = {}
    local BlockCounter = Counter

    while #Output < Length do
        local Block = GenerateBlock(Key, Nonce, BlockCounter)

        for Index = 1, #Block do
            if #Output >= Length then
                break
            end

            Output[#Output + 1] = Block[Index]
        end

        BlockCounter += 1
    end

    return Output
end

local function CreateAlphabet(Key)
    local Alphabet = {}

    for Index = 1, #BaseAlphabet do
        Alphabet[Index] = BaseAlphabet:sub(Index, Index)
    end

    local Stream = GenerateStream(Key, table.create(12, 0), 11259375, 128)

    for Index = 64, 2, -1 do
        local StreamIndex = 2 * (Index - 1) + 1
        local SwapIndex = (Stream[StreamIndex] * 256 + Stream[StreamIndex + 1]) % Index + 1

        Alphabet[Index], Alphabet[SwapIndex] = Alphabet[SwapIndex], Alphabet[Index]
    end

    return Alphabet
end

local function DecodeBase64(Input, ReverseAlphabet)
    local Output = {}
    local Buffer = 0
    local BitCount = 0

    for Index = 1, #Input do
        local Value = ReverseAlphabet[Input:sub(Index, Index)]

        if Value == nil then
            return nil, "Unsupported character at position " .. Index
        end

        Buffer = Buffer * 64 + Value
        BitCount += 6

        if BitCount >= 8 then
            BitCount -= 8
            Output[#Output + 1] = RShift(Buffer, BitCount) % 256
            Buffer = Buffer % (2 ^ BitCount)
        end
    end

    if BitCount == 6 then
        return nil, "Invalid Base64 length"
    end

    return Output
end

local function CreateTag(Key, Nonce, Ciphertext)
    local State = CreateState(Key, 4294967295, Nonce)

    Rounds(State)

    local Length = #Ciphertext
    local PaddedLength = Length + (16 - Length % 16) % 16

    for Offset = 0, PaddedLength - 1, 16 do
        for WordIndex = 0, 3 do
            local ByteOffset = Offset + WordIndex * 4
            local Value = (Ciphertext[ByteOffset + 1] or 0)
                + (Ciphertext[ByteOffset + 2] or 0) * 256
                + (Ciphertext[ByteOffset + 3] or 0) * 65536
                + (Ciphertext[ByteOffset + 4] or 0) * 16777216

            State[WordIndex + 1] = BXor(State[WordIndex + 1], Value)
        end

        Rounds(State)
    end

    State[1] = BXor(State[1], Length)
    Rounds(State)

    return WriteWord(State[1])
end

local function Decode(Token, Key)
    if type(Token) ~= "string" or Token:sub(1, #Prefix) ~= Prefix then
        return nil, "bad prefix"
    end

    local Alphabet = CreateAlphabet(Key)
    local ReverseAlphabet = {}

    for Index = 1, #Alphabet do
        ReverseAlphabet[Alphabet[Index]] = Index - 1
    end

    local Decoded, DecodeError = DecodeBase64(Token:sub(#Prefix + 1), ReverseAlphabet)

    if not Decoded then
        return nil, DecodeError
    end

    if #Decoded < 12 then
        return nil, "malformed"
    end

    local Nonce = table.create(12, 0)

    for Index = 1, 8 do
        Nonce[Index] = Decoded[Index]
    end

    local Tag = {}

    for Index = 1, 4 do
        Tag[Index] = Decoded[Index + 8]
    end

    local Ciphertext = {}

    for Index = 13, #Decoded do
        Ciphertext[#Ciphertext + 1] = Decoded[Index]
    end

    local ExpectedTag = CreateTag(Key, Nonce, Ciphertext)

    for Index = 1, 4 do
        if Tag[Index] ~= ExpectedTag[Index] then
            return nil, "bad tag"
        end
    end

    local Stream = GenerateStream(Key, Nonce, 1, #Ciphertext)
    local PlainText = {}

    for Index = 1, #Ciphertext do
        PlainText[Index] = string.char(BXor(Ciphertext[Index], Stream[Index]))
    end

    return table.concat(PlainText)
end

local Module = {}

function Module.Reverse(Token, Secret)
    local Key, KeyError = ParseKey(Secret)

    if not Key then
        return nil, KeyError
    end

    local Result, Error = Decode(Token, Key)

    if not Result then
        warn("Decode failed:", Error)
        return nil, Error
    end

    return Result
end

return Module
