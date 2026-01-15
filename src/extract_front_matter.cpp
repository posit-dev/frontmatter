#include <cpp11.hpp>
#include <string>
#include <cstring>
using namespace cpp11;

// PEP 723 delimiter lengths
// Opening: "# /// script" (12 chars, need 13 to check for trailing content)
const size_t PEP723_OPENING_LEN = 12;
const size_t PEP723_OPENING_CHECK_LEN = 13;
// Closing: "# ///" (5 chars)
const size_t PEP723_CLOSING_LEN = 5;

// Helper: Check if character is whitespace (space or tab)
inline bool is_whitespace(char c) {
  return c == ' ' || c == '\t';
}

// Helper: Check if we're at a newline (LF or CRLF)
inline bool is_newline(const char* str, size_t pos, size_t len) {
  if (pos >= len) return false;
  if (str[pos] == '\n') return true;
  if (str[pos] == '\r' && pos + 1 < len && str[pos + 1] == '\n') return true;
  return false;
}

// Helper: Skip to next line, return position after newline
inline size_t skip_to_next_line(const char* str, size_t pos, size_t len) {
  while (pos < len && !is_newline(str, pos, len)) {
    pos++;
  }
  if (pos < len) {
    if (str[pos] == '\r' && pos + 1 < len && str[pos + 1] == '\n') {
      pos += 2;  // CRLF
    } else if (str[pos] == '\n') {
      pos += 1;  // LF
    }
  }
  return pos;
}

// Helper: Check if fence is valid at given position
// Returns the position after the fence line (including newline), or 0 if invalid
size_t validate_fence(const char* str, size_t pos, size_t len, const char* fence_chars, bool is_opening) {
  // For opening fence: must be at position 0
  if (is_opening && pos != 0) {
    return 0;
  }

  // For closing fence: must be at start of line (preceded by newline)
  if (!is_opening && pos > 0 && !is_newline(str, pos - 1, len) && !(pos >= 2 && is_newline(str, pos - 2, len))) {
    // Need to be at start of line
    return 0;
  }

  // Check fence characters (exactly 3)
  if (pos + 3 > len) return 0;
  if (memcmp(str + pos, fence_chars, 3) != 0) {
    return 0;
  }

  // After fence, only whitespace until newline or end of string
  size_t i = pos + 3;
  while (i < len && is_whitespace(str[i])) {
    i++;
  }

  // Must end with newline or be at end of string
  if (i >= len) {
    return i;  // End of string is valid
  }

  if (is_newline(str, i, len)) {
    // Valid fence, return position after newline
    if (str[i] == '\r' && i + 1 < len && str[i + 1] == '\n') {
      return i + 2;  // CRLF
    } else {
      return i + 1;  // LF
    }
  }

  // Non-whitespace after fence - invalid
  return 0;
}

// Helper: Find closing fence starting from given position
// Returns position where fence line starts, or 0 if not found
size_t find_closing_fence(const char* str, size_t start_pos, size_t len, const char* fence_chars, size_t& content_end) {
  size_t pos = start_pos;

  while (pos < len) {
    // Check if we're at start of a line and this could be a closing fence
    bool at_line_start = (pos == start_pos) || is_newline(str, pos - 1, len) || (pos >= 2 && is_newline(str, pos - 2, len));

    if (at_line_start && pos + 3 <= len) {
      // Check if this is the closing fence
      size_t fence_end = validate_fence(str, pos, len, fence_chars, false);
      if (fence_end > 0) {
        // Found valid closing fence
        content_end = pos;
        return pos;
      }
    }

    // Not a closing fence, move to next line
    pos = skip_to_next_line(str, pos, len);
  }

  return 0;  // No closing fence found
}

// Helper: Trim leading empty lines from body
std::string trim_leading_empty_lines(const std::string& body) {
  size_t pos = 0;
  size_t len = body.length();

  while (pos < len) {
    // Check if line is empty (only whitespace)
    size_t line_start = pos;
    while (pos < len && is_whitespace(body[pos])) {
      pos++;
    }

    // If we hit a newline or end, this line is empty/whitespace-only
    if (pos >= len) {
      return "";  // Entire body is empty
    }

    if (body[pos] == '\n') {
      pos++;  // Skip LF
      continue;
    }
    if (body[pos] == '\r' && pos + 1 < len && body[pos + 1] == '\n') {
      pos += 2;  // Skip CRLF
      continue;
    }

    // Found non-whitespace, return from line start
    return body.substr(line_start);
  }

  return "";
}

// Helper: Check if line starts with comment prefix and fence
// Returns 0 if not found, otherwise returns length of prefix + fence
size_t check_comment_fence(const char* str, size_t pos, size_t len, const char* fence_chars, const char** out_prefix) {
  // Try "# " prefix: "# ---" or "# +++"
  if (pos + 5 <= len && str[pos] == '#' && str[pos + 1] == ' ' &&
      memcmp(str + pos + 2, fence_chars, 3) == 0) {
    *out_prefix = "# ";
    return 5;  // Length of "# ---" or "# +++"
  }

  // Try "#'" prefix (Roxygen style): "#' ---" or "#' +++"
  if (pos + 6 <= len && str[pos] == '#' && str[pos + 1] == '\'' &&
      str[pos + 2] == ' ' && memcmp(str + pos + 3, fence_chars, 3) == 0) {
    *out_prefix = "#' ";
    return 6;  // Length of "#' ---" or "#' +++"
  }

  return 0;
}

// Helper: Unwrap comment-prefixed content
std::string unwrap_comments(const std::string& content, const char* prefix) {
  size_t prefix_len = strlen(prefix);
  std::string result;
  result.reserve(content.length());

  const char* data = content.data();
  size_t pos = 0;
  size_t len = content.length();

  while (pos < len) {
    size_t line_content_start = pos;

    // Check if line starts with full prefix (e.g., "# " or "#' ")
    if (pos + prefix_len <= len && memcmp(data + pos, prefix, prefix_len) == 0) {
      // Skip the full prefix
      line_content_start = pos + prefix_len;
      pos = line_content_start;
    } else if (data[pos] == '#') {
      // Check for bare "#" (empty comment line) - only if prefix starts with #
      if (prefix[0] == '#') {
        size_t check_pos = pos + 1;

        // For "#' " prefix, check for bare "#'"
        if (prefix_len == 3 && prefix[1] == '\'' && check_pos < len && data[check_pos] == '\'') {
          check_pos++;
          // Skip trailing whitespace/newline
          while (check_pos < len && is_whitespace(data[check_pos])) {
            check_pos++;
          }
          if (check_pos >= len || data[check_pos] == '\n' || data[check_pos] == '\r') {
            // It's bare "#'" - skip it entirely, don't add to result
            pos = check_pos;
            if (pos < len && data[pos] == '\r') pos++;
            if (pos < len && data[pos] == '\n') pos++;
            continue;
          }
        }

        // For "# " prefix, check for bare "#"
        if (prefix_len == 2 && prefix[1] == ' ') {
          // Skip optional whitespace after bare #
          while (check_pos < len && is_whitespace(data[check_pos])) {
            check_pos++;
          }
          if (check_pos >= len || data[check_pos] == '\n' || data[check_pos] == '\r') {
            // It's bare "#" - skip it entirely
            pos = check_pos;
            if (pos < len && data[pos] == '\r') pos++;
            if (pos < len && data[pos] == '\n') pos++;
            continue;
          }
        }
      }
    }

    // Find end of line
    while (pos < len && data[pos] != '\n' && data[pos] != '\r') {
      pos++;
    }

    // Include newline in the copy
    if (pos < len) {
      if (data[pos] == '\r' && pos + 1 < len && data[pos + 1] == '\n') {
        pos += 2;  // CRLF
      } else {
        pos++;  // LF or CR
      }
    }

    // Copy entire line segment at once (from after prefix to end of line)
    if (pos > line_content_start) {
      result.append(data + line_content_start, pos - line_content_start);
    }
  }

  return result;
}

// Helper: Find closing fence for comment-wrapped format
size_t find_comment_closing_fence(const char* str, size_t start_pos, size_t len, const char* fence_chars, const char* prefix, size_t& content_end) {
  size_t pos = start_pos;

  while (pos < len) {
    // Check if we're at start of a line
    bool at_line_start = (pos == start_pos) || is_newline(str, pos - 1, len) || (pos >= 2 && is_newline(str, pos - 2, len));

    if (at_line_start) {
      // Check if this line is the closing fence with same comment prefix
      const char* found_prefix;
      size_t fence_len = check_comment_fence(str, pos, len, fence_chars, &found_prefix);
      if (fence_len > 0 && strcmp(found_prefix, prefix) == 0) {
        // Validate it's a complete fence line
        size_t check_pos = pos + fence_len;

        // Allow trailing whitespace
        while (check_pos < len && is_whitespace(str[check_pos])) {
          check_pos++;
        }

        // Must end with newline or EOF
        if (check_pos >= len || is_newline(str, check_pos, len)) {
          content_end = pos;
          return pos;
        }
      }
    }

    // Move to next line
    pos = skip_to_next_line(str, pos, len);
  }

  return 0;
}

// Helper: Trim leading blank/comment-only lines (for comment-wrapped formats)
// Only removes separator lines like "#" or "#'" - body is returned unchanged
std::string trim_leading_comment_lines(const std::string& body, const char* prefix) {
  const char* data = body.data();
  size_t pos = 0;
  size_t len = body.length();
  size_t prefix_len = strlen(prefix);

  // Skip leading empty lines and bare comment lines (separator lines)
  while (pos < len) {
    size_t line_start = pos;

    // Skip whitespace at start of line
    while (pos < len && is_whitespace(data[pos])) {
      pos++;
    }

    // Check if line is empty (just whitespace + newline)
    if (pos >= len || data[pos] == '\n' || (data[pos] == '\r' && pos + 1 < len && data[pos + 1] == '\n')) {
      // Empty line - skip it
      if (pos < len) {
        if (data[pos] == '\r') pos += 2;
        else pos++;
      }
      continue;
    }

    // Check if line is a bare comment character (e.g., "#" or "#'")
    // For "# " prefix, check for bare "#"
    if (prefix_len == 2 && prefix[0] == '#' && prefix[1] == ' ' && data[pos] == '#') {
      size_t check_pos = pos + 1;
      // Skip optional whitespace after bare #
      while (check_pos < len && is_whitespace(data[check_pos])) {
        check_pos++;
      }
      if (check_pos >= len || data[check_pos] == '\n' || (data[check_pos] == '\r' && check_pos + 1 < len && data[check_pos + 1] == '\n')) {
        // It's bare "#" - skip it
        pos = check_pos;
        if (pos < len) {
          if (data[pos] == '\r') pos += 2;
          else if (data[pos] == '\n') pos++;
        }
        continue;
      }
    }

    // For "#' " prefix, check for bare "#'"
    if (prefix_len == 3 && prefix[0] == '#' && prefix[1] == '\'' && prefix[2] == ' ' &&
        pos + 2 <= len && data[pos] == '#' && data[pos + 1] == '\'') {
      size_t check_pos = pos + 2;
      // Skip optional whitespace after bare #'
      while (check_pos < len && is_whitespace(data[check_pos])) {
        check_pos++;
      }
      if (check_pos >= len || data[check_pos] == '\n' || (data[check_pos] == '\r' && check_pos + 1 < len && data[check_pos + 1] == '\n')) {
        // It's bare "#'" - skip it
        pos = check_pos;
        if (pos < len) {
          if (data[pos] == '\r') pos += 2;
          else if (data[pos] == '\n') pos++;
        }
        continue;
      }
    }

    // Found a non-separator line - return from here unchanged
    return body.substr(line_start);
  }

  // Entire body was separator lines
  return "";
}

// Helper: Check if line starts with PEP 723 opening delimiter
bool is_pep723_opening(const char* str, size_t pos, size_t len) {
  // Must be exactly "# /// script" (# space /// space script)
  if (pos + PEP723_OPENING_CHECK_LEN > len) return false;
  if (str[pos] != '#') return false;
  if (str[pos + 1] != ' ') return false;
  if (str[pos + 2] != '/' || str[pos + 3] != '/' || str[pos + 4] != '/') return false;
  if (str[pos + 5] != ' ') return false;
  if (str[pos + 6] != 's' || str[pos + 7] != 'c' || str[pos + 8] != 'r' || str[pos + 9] != 'i' || str[pos + 10] != 'p' || str[pos + 11] != 't') return false;

  // After "script", only whitespace until newline or EOF
  size_t i = pos + PEP723_OPENING_LEN;
  while (i < len && is_whitespace(str[i])) {
    i++;
  }
  return (i >= len || is_newline(str, i, len));
}

// Helper: Check if line starts with PEP 723 closing delimiter
bool is_pep723_closing(const char* str, size_t pos, size_t len) {
  // Must be exactly "# ///" (# space /// and nothing else)
  if (pos + PEP723_CLOSING_LEN > len) return false;
  if (str[pos] != '#') return false;
  if (str[pos + 1] != ' ') return false;
  if (str[pos + 2] != '/' || str[pos + 3] != '/' || str[pos + 4] != '/') return false;

  // After "///", only whitespace until newline or EOF
  size_t i = pos + PEP723_CLOSING_LEN;
  while (i < len && is_whitespace(str[i])) {
    i++;
  }
  return (i >= len || is_newline(str, i, len));
}

// Helper: Extract PEP 723 content
list extract_pep723(const std::string& text) {
  const char* str = text.c_str();
  size_t len = text.length();
  writable::list result;

  // Check for opening at position 0
  if (!is_pep723_opening(str, 0, len)) {
    result.push_back({"found"_nm = false});
    result.push_back({"format"_nm = "none"});
    result.push_back({"fence_type"_nm = "none"});
    result.push_back({"content"_nm = ""});
    result.push_back({"body"_nm = text});
    return result;
  }

  // Skip opening line
  size_t pos = skip_to_next_line(str, 0, len);
  size_t content_start = pos;

  // Find closing delimiter and validate all lines in between
  while (pos < len) {
    // Check for closing delimiter
    if (is_pep723_closing(str, pos, len)) {
      // Found closing, extract content
      std::string content;
      if (pos > content_start) {
        content = text.substr(content_start, pos - content_start);
        // Unwrap "# " prefix from content
        content = unwrap_comments(content, "# ");
      }

      // Extract body
      size_t body_start = skip_to_next_line(str, pos, len);
      std::string body;
      if (body_start < len) {
        body = text.substr(body_start);
        // Use trim_leading_comment_lines to handle bare "#" separator lines
        body = trim_leading_comment_lines(body, "# ");
      }

      result.push_back({"found"_nm = true});
      result.push_back({"format"_nm = "toml"});
      result.push_back({"fence_type"_nm = "toml_pep723"});
      result.push_back({"content"_nm = content});
      result.push_back({"body"_nm = body});
      return result;
    }

    // Validate this line starts with "#"
    if (str[pos] != '#') {
      // Invalid PEP 723 block
      result.push_back({"found"_nm = false});
      result.push_back({"format"_nm = "none"});
      result.push_back({"fence_type"_nm = "none"});
      result.push_back({"content"_nm = ""});
      result.push_back({"body"_nm = text});
      return result;
    }

    // If there's content after #, must have space
    if (pos + 1 < len && str[pos + 1] != '\n' && str[pos + 1] != '\r' && str[pos + 1] != ' ') {
      // Invalid: no space after #
      result.push_back({"found"_nm = false});
      result.push_back({"format"_nm = "none"});
      result.push_back({"fence_type"_nm = "none"});
      result.push_back({"content"_nm = ""});
      result.push_back({"body"_nm = text});
      return result;
    }

    // Move to next line
    pos = skip_to_next_line(str, pos, len);
  }

  // No closing delimiter found
  result.push_back({"found"_nm = false});
  result.push_back({"format"_nm = "none"});
  result.push_back({"fence_type"_nm = "none"});
  result.push_back({"content"_nm = ""});
  result.push_back({"body"_nm = text});
  return result;
}

[[cpp11::register]]
list extract_front_matter_cpp(std::string text) {
  const char* str = text.c_str();
  size_t len = text.length();

  writable::list result;

  // Empty string
  if (len == 0) {
    result.push_back({"found"_nm = false});
    result.push_back({"format"_nm = "none"});
    result.push_back({"fence_type"_nm = "none"});
    result.push_back({"content"_nm = ""});
    result.push_back({"body"_nm = ""});
    return result;
  }

  // Check for PEP 723 format first (has most specific opening)
  if (is_pep723_opening(str, 0, len)) {
    return extract_pep723(text);
  }

  // Check for opening fence at position 0
  const char* fence_chars = nullptr;
  std::string format;
  std::string fence_type;
  const char* comment_prefix = nullptr;
  size_t opening_end = 0;
  bool is_comment_wrapped = false;

  // Try comment-wrapped YAML (# --- or #' ---)
  size_t comment_fence_len = check_comment_fence(str, 0, len, "---", &comment_prefix);
  if (comment_fence_len > 0) {
    // Validate it's a complete fence line
    size_t check_pos = comment_fence_len;
    while (check_pos < len && is_whitespace(str[check_pos])) {
      check_pos++;
    }
    if (check_pos >= len || is_newline(str, check_pos, len)) {
      fence_chars = "---";
      format = "yaml";
      // Determine fence_type based on prefix: "# " -> yaml_comment, "#' " -> yaml_roxy
      if (strcmp(comment_prefix, "# ") == 0) {
        fence_type = "yaml_comment";
      } else {
        fence_type = "yaml_roxy";
      }
      is_comment_wrapped = true;
      opening_end = skip_to_next_line(str, 0, len);
    }
  }

  // Try comment-wrapped TOML (# +++ or #' +++)
  if (!fence_chars) {
    comment_fence_len = check_comment_fence(str, 0, len, "+++", &comment_prefix);
    if (comment_fence_len > 0) {
      size_t check_pos = comment_fence_len;
      while (check_pos < len && is_whitespace(str[check_pos])) {
        check_pos++;
      }
      if (check_pos >= len || is_newline(str, check_pos, len)) {
        fence_chars = "+++";
        format = "toml";
        // Determine fence_type based on prefix: "# " -> toml_comment, "#' " -> toml_roxy
        if (strcmp(comment_prefix, "# ") == 0) {
          fence_type = "toml_comment";
        } else {
          fence_type = "toml_roxy";
        }
        is_comment_wrapped = true;
        opening_end = skip_to_next_line(str, 0, len);
      }
    }
  }

  // Try standard YAML (---)
  if (!fence_chars) {
    opening_end = validate_fence(str, 0, len, "---", true);
    if (opening_end > 0) {
      fence_chars = "---";
      format = "yaml";
      fence_type = "yaml";
    }
  }

  // Try standard TOML (+++)
  if (!fence_chars) {
    opening_end = validate_fence(str, 0, len, "+++", true);
    if (opening_end > 0) {
      fence_chars = "+++";
      format = "toml";
      fence_type = "toml";
    }
  }

  // No valid opening fence found
  if (!fence_chars) {
    result.push_back({"found"_nm = false});
    result.push_back({"format"_nm = "none"});
    result.push_back({"fence_type"_nm = "none"});
    result.push_back({"content"_nm = ""});
    result.push_back({"body"_nm = text});
    return result;
  }

  // Opening fence found, now find closing fence
  size_t content_end;
  size_t closing_start;

  if (is_comment_wrapped) {
    closing_start = find_comment_closing_fence(str, opening_end, len, fence_chars, comment_prefix, content_end);
  } else {
    closing_start = find_closing_fence(str, opening_end, len, fence_chars, content_end);
  }

  if (closing_start == 0) {
    // No valid closing fence found or limits exceeded
    result.push_back({"found"_nm = false});
    result.push_back({"format"_nm = "none"});
    result.push_back({"fence_type"_nm = "none"});
    result.push_back({"content"_nm = ""});
    result.push_back({"body"_nm = text});
    return result;
  }

  // Extract content between fences
  std::string content;
  if (content_end > opening_end) {
    content = text.substr(opening_end, content_end - opening_end);
    // Unwrap comments if needed
    if (is_comment_wrapped) {
      content = unwrap_comments(content, comment_prefix);
    }
  }

  // Extract body (everything after closing fence line)
  size_t body_start = skip_to_next_line(str, closing_start, len);
  std::string body;
  if (body_start < len) {
    body = text.substr(body_start);
    if (is_comment_wrapped) {
      // For comment-wrapped formats, trim leading comment lines then unwrap remaining
      body = trim_leading_comment_lines(body, comment_prefix);
    } else {
      body = trim_leading_empty_lines(body);
    }
  }

  result.push_back({"found"_nm = true});
  result.push_back({"format"_nm = format});
  result.push_back({"fence_type"_nm = fence_type});
  result.push_back({"content"_nm = content});
  result.push_back({"body"_nm = body});
  return result;
}
