using Microsoft.OpenApi;
using Swashbuckle.AspNetCore.SwaggerGen;
using System.Reflection;

namespace DrinkApi.Auth;

/// <summary>
/// Khai báo yêu cầu bảo mật "AdminKey" cho các action có [AdminKey] để Swagger UI
/// thực sự gửi header X-Admin-Key sau khi bấm Authorize.
/// </summary>
public class AdminKeyOperationFilter : IOperationFilter
{
    public const string SchemeName = "AdminKey";

    public void Apply(OpenApiOperation operation, OperationFilterContext context)
    {
        var hasAdminKey = context.MethodInfo
            .GetCustomAttributes<AdminKeyAttribute>(inherit: true)
            .Any();

        if (!hasAdminKey)
        {
            return;
        }

        operation.Security ??= new List<OpenApiSecurityRequirement>();
        operation.Security.Add(new OpenApiSecurityRequirement
        {
            [new OpenApiSecuritySchemeReference(SchemeName, context.Document)] = []
        });
    }
}
