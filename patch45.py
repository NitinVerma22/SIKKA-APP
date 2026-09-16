import re

file_path = r'e:\development\SikkaPlay\lib\shared\layouts\main_layout.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Make sure we don't accidentally do it twice if I run this multiple times
if '_fetchFriendsAndCheckMessages();' not in content.split('_handleIncomingMessageSocket')[-1]:
    # Replace the end of _handleIncomingMessageSocket to also fetch friends
    old_code = """          _showSystemLocalNotification(friendName, text, channelName, senderId);
        }
      } catch (e) {
        debugPrint('[Socket] Error handling message: $e');
      }
    }"""
    
    new_code = """          _showSystemLocalNotification(friendName, text, channelName, senderId);
        }
        
        // Always refresh friends list to update badges for the incoming message
        _fetchFriendsAndCheckMessages();
      } catch (e) {
        debugPrint('[Socket] Error handling message: $e');
      }
    }"""
    
    content = content.replace(old_code, new_code)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Patched main_layout.dart to refresh friends list on new message.")
else:
    print("Already patched.")
