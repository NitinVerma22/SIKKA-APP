# Rule: Previous Chat History and Context

Any time the user requests new features, bug fixes, refactoring, or asks about historical development context for SikkaPlay or other workspace files:

1. **Check Recovered Chats**: Consult the [Recovered Chats Index](file:///e:/development/SikkaPlay/recovered_chats/README.md) to see if this task, feature, or file has been worked on in previous conversations.
2. **Read Transcripts**: If relevant past chats exist under [recovered_chats/SikkaPlay/](file:///e:/development/SikkaPlay/recovered_chats/SikkaPlay/) or [recovered_chats/General/](file:///e:/development/SikkaPlay/recovered_chats/General/), read those files (and their associated `.md` implementation plans/walkthroughs) to understand:
   - What architectural decisions were made.
   - What bugs/issues were resolved.
   - What specific APIs or libraries (like Firebase, Redis, etc.) were used.
   - How the existing feature is structured.
3. **Align with Past Work**: Build on top of the previously completed work rather than rewriting it, ensuring consistency and avoiding regression.
