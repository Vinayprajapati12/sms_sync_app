class Conversation {
final String address; // phone number
final String displayName; // contact name if found or phone number
final String snippet; // last message snippet
final DateTime date; // last message date
final List<dynamic> messages; // raw messages for this conversation


Conversation({
required this.address,
required this.displayName,
required this.snippet,
required this.date,
required this.messages,
});
}