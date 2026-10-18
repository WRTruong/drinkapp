namespace DrinkApi.Dtos;

public record CreateOrderItemDto(
    int DrinkId, int Quantity,
    string? Size, string? SugarLevel, string? IceLevel);

public record CreateOrderDto(
    string CustomerName, string Phone, string? Note,
    List<CreateOrderItemDto> Items);

public record UpdateStatusDto(string Status);