
class PracticeGameService {

  int toss(){
    // Simulate a coin toss
    return DateTime.now().millisecondsSinceEpoch % 2 == 0 ? 1 : 2; // 1 for heads, 2 for tails
  }
}