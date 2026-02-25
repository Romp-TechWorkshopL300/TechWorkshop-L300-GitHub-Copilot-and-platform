using Azure;
using Azure.AI.ContentSafety;
using Azure.Identity;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace ZavaStorefront.Services;

public class ContentSafetyResult
{
    public bool IsSafe { get; set; }
    public string? Reason { get; set; }
}

public class ContentSafetyService
{
    private readonly ContentSafetyClient _client;
    private readonly ILogger<ContentSafetyService> _logger;
    private readonly DefaultAzureCredential _credential;
    private readonly string _endpoint;

    public ContentSafetyService(IConfiguration configuration, ILogger<ContentSafetyService> logger)
    {
        _logger = logger;
        _endpoint = configuration["AI:Endpoint"]
            ?? throw new InvalidOperationException("AI:Endpoint configuration is required");
        _credential = new DefaultAzureCredential();
        _client = new ContentSafetyClient(new Uri(_endpoint), _credential);
    }

    public async Task<ContentSafetyResult> EvaluateAsync(string text)
    {
        // 1. Check standard categories (hate, self-harm, sexual, violence)
        var categoryResult = await CheckCategoriesAsync(text);
        if (!categoryResult.IsSafe)
            return categoryResult;

        // 2. Check for jailbreak/prompt injection via Prompt Shield REST API
        var jailbreakResult = await CheckJailbreakAsync(text);
        if (!jailbreakResult.IsSafe)
            return jailbreakResult;

        _logger.LogInformation("Content safety check passed for input text");
        return new ContentSafetyResult { IsSafe = true };
    }

    private async Task<ContentSafetyResult> CheckCategoriesAsync(string text)
    {
        try
        {
            var options = new AnalyzeTextOptions(text);
            var response = await _client.AnalyzeTextAsync(options);

            foreach (var analysis in response.Value.CategoriesAnalysis)
            {
                if (analysis.Severity.HasValue && analysis.Severity.Value >= 2)
                {
                    _logger.LogWarning(
                        "Content safety violation: {Category} severity {Severity}",
                        analysis.Category, analysis.Severity.Value);
                    return new ContentSafetyResult
                    {
                        IsSafe = false,
                        Reason = $"{analysis.Category} content detected (severity {analysis.Severity.Value})"
                    };
                }
            }

            return new ContentSafetyResult { IsSafe = true };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Content safety category check failed");
            return new ContentSafetyResult { IsSafe = false, Reason = "Safety check unavailable" };
        }
    }

    private async Task<ContentSafetyResult> CheckJailbreakAsync(string text)
    {
        try
        {
            var token = await _credential.GetTokenAsync(
                new Azure.Core.TokenRequestContext(["https://cognitiveservices.azure.com/.default"]));

            using var httpClient = new HttpClient();
            httpClient.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", token.Token);

            var requestBody = JsonSerializer.Serialize(new
            {
                userPrompt = text,
                documents = Array.Empty<string>()
            });

            var response = await httpClient.PostAsync(
                $"{_endpoint.TrimEnd('/')}/contentsafety/text:shieldPrompt?api-version=2024-09-01",
                new StringContent(requestBody, Encoding.UTF8, "application/json"));

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Prompt shield API returned {StatusCode}", response.StatusCode);
                return new ContentSafetyResult { IsSafe = true };
            }

            var json = await JsonDocument.ParseAsync(await response.Content.ReadAsStreamAsync());
            var attackDetected = json.RootElement
                .GetProperty("userPromptAnalysis")
                .GetProperty("attackDetected")
                .GetBoolean();

            if (attackDetected)
            {
                _logger.LogWarning("Jailbreak/prompt injection detected");
                return new ContentSafetyResult
                {
                    IsSafe = false,
                    Reason = "Potential jailbreak attempt detected"
                };
            }

            return new ContentSafetyResult { IsSafe = true };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Prompt shield check failed");
            return new ContentSafetyResult { IsSafe = true };
        }
    }
}
