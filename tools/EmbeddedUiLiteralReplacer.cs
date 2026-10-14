using System;
using System.Collections.Generic;
using System.Text;

public sealed class DevinEmbeddedUiReplaceResult
{
    public string Text { get; private set; }
    public int MatchCount { get; private set; }

    public DevinEmbeddedUiReplaceResult(string text, int matchCount)
    {
        Text = text;
        MatchCount = matchCount;
    }
}

public static class DevinEmbeddedUiLiteralReplacer
{
    public static DevinEmbeddedUiReplaceResult Replace(string text, IDictionary<string, string> replacements)
    {
        var possibleLengths = new HashSet<int>();
        foreach (var key in replacements.Keys)
            possibleLengths.Add(key.Length);

        var output = new StringBuilder(text.Length);
        var matches = 0;
        var index = 0;

        while (index < text.Length)
        {
            var quote = text[index];
            if (quote == '"' || quote == '\'')
            {
                var end = index + 1;
                while (end < text.Length)
                {
                    if (text[end] == '\\')
                    {
                        end += 2;
                        continue;
                    }

                    if (text[end] == quote)
                    {
                        end++;
                        break;
                    }

                    end++;
                }

                if (end <= text.Length && end > index + 1 && text[end - 1] == quote)
                {
                    var length = end - index;
                    if (possibleLengths.Contains(length))
                    {
                        var literal = text.Substring(index, length);
                        string localized;
                        if (replacements.TryGetValue(literal, out localized))
                        {
                            output.Append(localized);
                            matches++;
                            index = end;
                            continue;
                        }
                    }

                    output.Append(text, index, length);
                    index = end;
                    continue;
                }
            }

            output.Append(text[index]);
            index++;
        }

        return new DevinEmbeddedUiReplaceResult(output.ToString(), matches);
    }
}
