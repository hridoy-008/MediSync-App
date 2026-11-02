import '../domain/quiz_question.dart';

/// Offline question bank. Each entry lists the correct answer first; the quiz
/// service shuffles the options before showing them.
class RawQuizQuestion {
  const RawQuizQuestion(this.id, this.text, this.correct, this.wrong);
  final String id;
  final String text;
  final String correct;
  final List<String> wrong;
  QuizQuestion toQuestion() => QuizQuestion(
        id: id,
        text: text,
        options: [correct, ...wrong],
        correctIndex: 0,
      );
}

const List<RawQuizQuestion> quizQuestionBank = [
  RawQuizQuestion(
    'q01',
    'Which planet is known as the Red Planet?',
    'Mars',
    ['Earth', 'Venus', 'Jupiter'],
  ),
  RawQuizQuestion(
    'q02',
    'What is the largest planet in our solar system?',
    'Jupiter',
    ['Saturn', 'Neptune', 'Mars'],
  ),
  RawQuizQuestion(
    'q03',
    'Which star lights up our day?',
    'The Sun',
    ['Sirius', 'The North Star', 'Proxima Centauri'],
  ),
  RawQuizQuestion(
    'q04',
    'How many days are there in a week?',
    '7',
    ['5', '6', '8'],
  ),
  RawQuizQuestion(
    'q05',
    'How many months are there in a year?',
    '12',
    ['10', '11', '13'],
  ),
  RawQuizQuestion(
    'q06',
    'Which gas do humans need to breathe in to live?',
    'Oxygen',
    ['Helium', 'Nitrogen', 'Hydrogen'],
  ),
  RawQuizQuestion(
    'q07',
    'What is the capital of Bangladesh?',
    'Dhaka',
    ['Chattogram', 'Sylhet', 'Khulna'],
  ),
  RawQuizQuestion(
    'q08',
    'What is the capital of France?',
    'Paris',
    ['Lyon', 'Marseille', 'Nice'],
  ),
  RawQuizQuestion(
    'q09',
    'What is the capital of Japan?',
    'Tokyo',
    ['Osaka', 'Kyoto', 'Nagoya'],
  ),
  RawQuizQuestion(
    'q10',
    'What is the capital of India?',
    'New Delhi',
    ['Mumbai', 'Kolkata', 'Chennai'],
  ),
  RawQuizQuestion(
    'q11',
    'Which is the largest ocean on Earth?',
    'Pacific Ocean',
    ['Atlantic Ocean', 'Indian Ocean', 'Arctic Ocean'],
  ),
  RawQuizQuestion(
    'q12',
    'Which is the longest river in Bangladesh region\'s delta system, formed with the Ganges?',
    'Brahmaputra',
    ['Nile', 'Amazon', 'Danube'],
  ),
  RawQuizQuestion(
    'q13',
    'What is the national flower of Bangladesh?',
    'Water Lily',
    ['Rose', 'Lotus', 'Jasmine'],
  ),
  RawQuizQuestion(
    'q14',
    'What is the national animal of Bangladesh?',
    'Royal Bengal Tiger',
    ['Elephant', 'Lion', 'Deer'],
  ),
  RawQuizQuestion(
    'q15',
    'How many colours are there in a rainbow?',
    '7',
    ['5', '6', '9'],
  ),
  RawQuizQuestion(
    'q16',
    'What is 9 + 6?',
    '15',
    ['14', '16', '13'],
  ),
  RawQuizQuestion(
    'q17',
    'What is 8 x 7?',
    '56',
    ['54', '48', '64'],
  ),
  RawQuizQuestion(
    'q18',
    'What is 100 minus 37?',
    '63',
    ['73', '67', '57'],
  ),
  RawQuizQuestion(
    'q19',
    'What is 144 divided by 12?',
    '12',
    ['14', '11', '13'],
  ),
  RawQuizQuestion(
    'q20',
    'What is the square root of 81?',
    '9',
    ['8', '7', '11'],
  ),
  RawQuizQuestion(
    'q21',
    'Which animal is known as the King of the Jungle?',
    'Lion',
    ['Tiger', 'Elephant', 'Leopard'],
  ),
  RawQuizQuestion(
    'q22',
    'Which is the largest land animal?',
    'African Elephant',
    ['Giraffe', 'Rhinoceros', 'Hippopotamus'],
  ),
  RawQuizQuestion(
    'q23',
    'Which bird cannot fly?',
    'Ostrich',
    ['Sparrow', 'Eagle', 'Crow'],
  ),
  RawQuizQuestion(
    'q24',
    'What do bees make?',
    'Honey',
    ['Milk', 'Silk', 'Butter'],
  ),
  RawQuizQuestion(
    'q25',
    'Which organ pumps blood around the body?',
    'Heart',
    ['Lungs', 'Liver', 'Kidney'],
  ),
  RawQuizQuestion(
    'q26',
    'How many bones are in the adult human body?',
    '206',
    ['106', '306', '406'],
  ),
  RawQuizQuestion(
    'q27',
    'Which vitamin do we get from sunlight?',
    'Vitamin D',
    ['Vitamin C', 'Vitamin A', 'Vitamin B12'],
  ),
  RawQuizQuestion(
    'q28',
    'What is the hardest natural substance?',
    'Diamond',
    ['Gold', 'Iron', 'Quartz'],
  ),
  RawQuizQuestion(
    'q29',
    'What is H2O commonly known as?',
    'Water',
    ['Salt', 'Hydrogen', 'Oxygen'],
  ),
  RawQuizQuestion(
    'q30',
    'At what temperature does water boil at sea level?',
    '100 °C',
    ['50 °C', '90 °C', '120 °C'],
  ),
  RawQuizQuestion(
    'q31',
    'Which planet is closest to the Sun?',
    'Mercury',
    ['Venus', 'Earth', 'Mars'],
  ),
  RawQuizQuestion(
    'q32',
    'Which is the smallest continent by land area?',
    'Australia',
    ['Europe', 'Antarctica', 'South America'],
  ),
  RawQuizQuestion(
    'q33',
    'Which is the largest continent?',
    'Asia',
    ['Africa', 'North America', 'Europe'],
  ),
  RawQuizQuestion(
    'q34',
    'Which country has the Great Wall?',
    'China',
    ['India', 'Japan', 'Egypt'],
  ),
  RawQuizQuestion(
    'q35',
    'Who wrote the national anthem of Bangladesh?',
    'Rabindranath Tagore',
    ['Kazi Nazrul Islam', 'Jibanananda Das', 'Michael Madhusudan Dutt'],
  ),
  RawQuizQuestion(
    'q36',
    'In which month is Bangladesh\'s Victory Day celebrated?',
    'December',
    ['March', 'February', 'August'],
  ),
  RawQuizQuestion(
    'q37',
    'On which date is International Mother Language Day observed?',
    '21 February',
    ['26 March', '16 December', '14 April'],
  ),
  RawQuizQuestion(
    'q38',
    'What colour do you get by mixing blue and yellow?',
    'Green',
    ['Purple', 'Orange', 'Brown'],
  ),
  RawQuizQuestion(
    'q39',
    'How many hours are there in a day?',
    '24',
    ['12', '36', '48'],
  ),
  RawQuizQuestion(
    'q40',
    'How many minutes are there in an hour?',
    '60',
    ['100', '30', '90'],
  ),
  RawQuizQuestion(
    'q41',
    'Which season comes after winter?',
    'Spring',
    ['Autumn', 'Summer', 'Monsoon'],
  ),
  RawQuizQuestion(
    'q42',
    'Which fruit is known for keeping \'the doctor away\'?',
    'Apple',
    ['Banana', 'Mango', 'Grapes'],
  ),
  RawQuizQuestion(
    'q43',
    'Which meal is eaten first in the day?',
    'Breakfast',
    ['Lunch', 'Dinner', 'Supper'],
  ),
  RawQuizQuestion(
    'q44',
    'Which drink is recommended for staying hydrated?',
    'Water',
    ['Soda', 'Coffee', 'Energy drink'],
  ),
  RawQuizQuestion(
    'q45',
    'How many sides does a triangle have?',
    '3',
    ['4', '5', '6'],
  ),
  RawQuizQuestion(
    'q46',
    'How many legs does a spider have?',
    '8',
    ['6', '10', '4'],
  ),
  RawQuizQuestion(
    'q47',
    'Which is the tallest animal?',
    'Giraffe',
    ['Elephant', 'Camel', 'Horse'],
  ),
  RawQuizQuestion(
    'q48',
    'Which sense organ do we use to see?',
    'Eyes',
    ['Ears', 'Nose', 'Tongue'],
  ),
  RawQuizQuestion(
    'q49',
    'Which planet has prominent rings?',
    'Saturn',
    ['Mars', 'Mercury', 'Earth'],
  ),
  RawQuizQuestion(
    'q50',
    'What is the opposite of \'night\'?',
    'Day',
    ['Moon', 'Dark', 'Evening'],
  ),
];
