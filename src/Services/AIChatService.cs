using Azure.AI.OpenAI;
using Azure.Identity;
using OpenAI.Chat;

namespace ZavaStorefront.Services;

public class AIChatService
{
    private readonly ChatClient _chatClient;
    private readonly ILogger<AIChatService> _logger;

    public AIChatService(IConfiguration configuration, ILogger<AIChatService> logger)
    {
        _logger = logger;
        var endpoint = configuration["AI:Endpoint"]
            ?? throw new InvalidOperationException("AI:Endpoint configuration is required");
        var deployment = configuration["AI:DeploymentName"] ?? "gpt-4o";

        var azureClient = new AzureOpenAIClient(new Uri(endpoint), new DefaultAzureCredential());
        _chatClient = azureClient.GetChatClient(deployment);
    }

    public async Task<string> GetResponseAsync(string userMessage)
    {
        _logger.LogInformation("Sending chat request to Azure OpenAI");

        var messages = new ChatMessage[]
        {
            new SystemChatMessage("You are a helpful shopping assistant for Zava Storefront, an online tech store. Keep responses concise and friendly."),
            new UserChatMessage(userMessage)
        };

        var completion = await _chatClient.CompleteChatAsync(messages);
        var reply = completion.Value.Content[0].Text;

        _logger.LogInformation("Received chat response");
        return reply;
    }
}
