/// Report categories and sub-reasons for GOTCHAA trust & safety.
class ReportCategories {
  ReportCategories._();

  static const Map<String, List<String>> categories = {
    'Spam': ['Repetitive content', 'Fake account', 'Bot'],
    'Hate Speech': ['Race/ethnicity', 'Religion', 'Gender', 'Sexual orientation'],
    'Nudity': ['Explicit content', 'Partial nudity'],
    'Violence': ['Graphic violence', 'Threats', 'Self harm'],
    'Harassment': ['Bullying', 'Doxxing', 'Stalking'],
    'Misinformation': ['False news', 'Health misinformation'],
    'Child Safety': ['Exploitation', 'Grooming'],
    'Other': ['Describe'],
  };

  static bool isChildSafety(String category) => category == 'Child Safety';
}
