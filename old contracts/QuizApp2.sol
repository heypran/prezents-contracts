// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract NewApp{
     uint public constant QUIZ_LENGTH=4;
     uint public constant QUIZ_REWARD_FACTOR= 1;
    uint public constant REWARD_PER_SCORE= 0.005 ether; // should be more
    uint public constant REWARD_PER_SCORE_QUIZ_END= 0.001 ether; //


     event QuizCreated(uint indexed quizId, address indexed createdBy, string indexed cid);
     event QuizUpdated(uint indexed quizId, address indexed createdBy, string indexed cid);
     event QuizEnded(uint indexed quizId, address indexed createdBy, string indexed cid);
     event QuizAnswerSubmitted(uint indexed quizId, address indexed submittedBy);
     event RewardRedemption(address indexed user, uint indexed rewards);

    struct Quiz{
        uint quizId;
        address creator;
        string cid;
        string title;
        // uint count;
        uint attemptedCount;
        uint rewards; // total rewards available for the correct answers        
        uint created;
        uint startTime;
        uint endTime;
        bool isActive;
        uint8[QUIZ_LENGTH] answers;
    }

    struct QuizSubmission{
        uint quizId;
        address user;
        uint redeemedRewards;       
        uint submissionTime;
        uint8[QUIZ_LENGTH] answers;
    }


    mapping(uint=>Quiz) public quizIdMapping;
    
    // answers follow the sequence of questions
    mapping(address=>mapping(uint=>uint8[QUIZ_LENGTH])) public quizSubmission;
    mapping(address=>uint) public userRewards;
    
    // quiz created/attempted by user
    mapping(address=>uint[]) public userQuizIdMapping;
    mapping(address=>uint[]) public userAttemptedQuizIds;
    
    mapping(address=>mapping(uint=>QuizSubmission)) public userQuizSubmissionMapping;

    // track of quiz counts
    uint quizId;

    constructor(){}

    function createQuiz(string memory _cid, string memory _title, uint _rewards) public {
        
        quizIdMapping[quizId].quizId = quizId;
        quizIdMapping[quizId].creator= msg.sender;
        quizIdMapping[quizId].cid = _cid;
        quizIdMapping[quizId].title= _title;
        quizIdMapping[quizId].rewards= _rewards;
        quizIdMapping[quizId].created= block.timestamp;
        // quizIdMapping[quizId].isActive= true; // atm create is active, later can be approval based.        
        
        userQuizIdMapping[msg.sender].push(quizId);
        
        emit QuizCreated(quizId,msg.sender,_cid);
        
        quizId+=1;
    }

    function updateQuizDetails(uint _quizId,string memory _cid, string memory _title, uint _rewards) public{
        require(_quizId<quizId,"Not a valid ID");
        require(msg.sender == quizIdMapping[_quizId].creator,"Not owner");
        // TODO cannot update quiz if started

        Quiz storage quiz = quizIdMapping[_quizId];
        quiz.cid = _cid;
        quiz.title= _title;
        quiz.rewards= _rewards;

        emit QuizUpdated(quizId,msg.sender,_cid);
    }

  // start quiz 
    function startQuiz(uint _quizId,uint _endTime) public{
        require(_quizId<quizId,"Not a valid ID");
        require(msg.sender == quizIdMapping[_quizId].creator,"Not owner");
        require(quizIdMapping[_quizId].endTime == 0,"Alread ended.");
        // require(quizIdMapping[_quizId].isActive,"Not active");

        Quiz storage quiz = quizIdMapping[_quizId];
        quiz.startTime= block.timestamp;
        quiz.endTime= _endTime;
        quiz.isActive=true;

        emit QuizEnded(_quizId,msg.sender,quiz.cid);
    }

    // end quiz by publish results
    function endQuiz(uint _quizId, uint8[QUIZ_LENGTH] memory _answers) public{
        require(_quizId<quizId,"Not a valid ID");
        require(msg.sender == quizIdMapping[_quizId].creator,"Not owner");
        require(quizIdMapping[_quizId].endTime <block.timestamp,"Cannot end.");

        Quiz storage quiz = quizIdMapping[_quizId];
        // quiz.endTime= block.timestamp;
        quiz.answers=_answers;
    }

    // submit answers
    function submitAnswers(uint _quizId, uint8[QUIZ_LENGTH] memory _answers) public{
        require(_quizId<quizId,"Not a valid ID.");
        require(quizIdMapping[_quizId].isActive,"Not a active.");
        require(quizIdMapping[_quizId].startTime < block.timestamp,"Not a valid ID.");
        // TODO add owner cannot re submit
        // TODO add owner cannot submitAnswers

        quizSubmission[msg.sender][_quizId]=_answers;
        quizIdMapping[_quizId].attemptedCount+=1;


        userQuizSubmissionMapping[msg.sender][_quizId].quizId=_quizId;
        userQuizSubmissionMapping[msg.sender][_quizId].answers=_answers;
        userQuizSubmissionMapping[msg.sender][_quizId].user=msg.sender;
        userQuizSubmissionMapping[msg.sender][_quizId].submissionTime=block.timestamp;
        

        // TODO remove
        userQuizIdMapping[msg.sender].push(_quizId);
        
        // to keep track of attempt
        userAttemptedQuizIds[msg.sender].push(_quizId);

        // TODO  esitmate rewards here
        // can't be here as round has not ended yet.
        // userRewards[msg.sender]=1 ether;

        emit QuizAnswerSubmitted(_quizId,msg.sender);

    }

    function submitAnswersPostQuizEnd(uint _quizId, uint8[QUIZ_LENGTH] memory _answers) public{
        require(_quizId<quizId,"Not a valid ID.");
        require(quizIdMapping[_quizId].isActive,"Not a active.");
        require(quizIdMapping[_quizId].endTime < block.timestamp,"Cannot submit.");
        // TODO add owner cannot re submit
        // TODO add owner cannot submitAnswers
        
        quizSubmission[msg.sender][_quizId]=_answers;
        quizIdMapping[_quizId].attemptedCount+=1;

        // to keep track of attempt
        userAttemptedQuizIds[msg.sender].push(_quizId);

        // esitmate rewards here
        Quiz memory quiz = quizIdMapping[_quizId];
        uint8[QUIZ_LENGTH] memory actualAnswers = quiz.answers;
        uint score = 0;


        for(uint i =0;i<actualAnswers.length;++i){
            if(_answers[i] == actualAnswers[i]){
                score+=1;
            }
        }
        // add to user rewards
        userRewards[msg.sender]+=userScore * REWARD_PER_SCORE_QUIZ_END;
        
        emit QuizAnswerSubmitted(_quizId,msg.sender);

    }


    function redeemRewards(uint _quizId) public{
        // require(userRewards[msg.sender]>0,"No rewards.");
        uint score = calculateScore(msg.sender,_quizId);
        require(score>0,"Score 0");
        require(userQuizSubmissionMapping[msg.sender][_quizId].redeemedRewards == 0,"No rewards");

        // uint rewards = userRewards[msg.sender];
        uint rewards = score * QUIZ_REWARD_FACTOR * REWARD_PER_SCORE;

        // userRewards[msg.sender]=0;
        userQuizSubmissionMapping[msg.sender][_quizId].redeemedRewards=rewards;

       (bool success, ) = payable(address(msg.sender)).call{
                value: rewards
            }("");

        require(success, "Fail to transfer rewards");
        
    }

    function redeemAllRewards() public{
        require(userRewards[msg.sender]>0,"No rewards.");
        uint rewards = userRewards[msg.sender];
        uint rewards = calculateScore(_user,_quizId) * QUIZ_REWARD_FACTOR * REWARD_PER_SCORE;

        userRewards[msg.sender]=0;

       (bool success, ) = payable(address(msg.sender)).call{
                value: rewards
            }("");
        require(success, "Fail to transfer rewards");
        
    }


    function calculateScore(address _user,uint _quizId) public view returns (uint) {
        require(quizIdMapping[_quizId].isActive,"Not a valid ID.");
        require(quizIdMapping[_quizId].endTime <block.timestamp,"Quiz in progress.");

        uint8[QUIZ_LENGTH] memory userAnswers = userQuizSubmissionMapping[msg.sender][_quizId].answers; // quizSubmission[_user][_quizId];
        Quiz memory quiz = quizIdMapping[_quizId];
        uint8[QUIZ_LENGTH] memory actualAnswers = quiz.answers;
        uint score = 0;

        for(uint i =0;i<actualAnswers.length;++i){
            if(userAnswers[i] == actualAnswers[i]){
                score+=1;
            }
        }

        return score;

    }

       function calculateTotalScore(address _user) public view returns (uint) {
        // require(quizIdMapping[_quizId].isActive,"Not a valid ID.");
        // require(quizIdMapping[_quizId].endTime <block.timestamp,"Quiz in progress.");
        uint[] memory userAttemptedQuiz = userAttemptedQuizIds[_user];
        uint score = 0;
        for(uint i =0;i<userAttemptedQuiz.length;++i){
            uint quizId = userAttemptedQuiz[i];
            uint8[QUIZ_LENGTH] memory userAnswers = userQuizSubmissionMapping[msg.sender][_quizId].answers;
            Quiz memory quiz = quizIdMapping[quizId];
            uint8[QUIZ_LENGTH] memory actualAnswers = quiz.answers;
            for(uint i =0;i<actualAnswers.length;++i){
                if(userAnswers[i] == actualAnswers[i]){
                    score+=1;
                }
            }
        }

        // uint8[QUIZ_LENGTH] memory userAnswers = userQuizSubmissionMapping[msg.sender][_quizId].answers; // quizSubmission[_user][_quizId];
        // Quiz memory quiz = quizIdMapping[_quizId];
        // uint8[QUIZ_LENGTH] memory actualAnswers = quiz.answers;
        // uint score = 0;

        // for(uint i =0;i<actualAnswers.length;++i){
        //     if(userAnswers[i] == actualAnswers[i]){
        //         score+=1;
        //     }
        // }

        return score;

    }


    function calculateRewards(address _user,uint _quizId) public view returns (uint){
        uint userScore = calculateScore(_user,_quizId);
        return userScore * QUIZ_REWARD_FACTOR * REWARD_PER_SCORE; // this can be calculated by using rewards/attemptedCount
    }

      function getTotalRewards(address _user,uint _quizId) public view returns (uint){
        uint userScore = calculateScore(_user,_quizId);
        uint rewards userScore * QUIZ_REWARD_FACTOR * REWARD_PER_SCORE; // this can be calculated by using rewards/attemptedCount
    }


    function getQuizDetails(uint _quizId) public view returns (Quiz memory quiz){
        return quizIdMapping[_quizId];
    }


    function getQuizByUser(address _user) public view returns (Quiz[] memory){
        uint[] memory quizIds = userQuizIdMapping[_user];
        require(quizIds.length > 0,"No quiz.");

        Quiz[] memory quizzes = new Quiz[](quizIds.length);
        for ( uint i =0;i<quizIds.length;++i){
            quizzes[i]=quizIdMapping[quizIds[i]];
        }
        return quizzes;
    }

    // returns all quizzes
    function getAllQuizzes() public view returns (Quiz[] memory ){
        Quiz[] memory quizzes = new Quiz[](quizId+1);
        for ( uint i =0;i<quizId;++i){
            quizzes[i]=quizIdMapping[i];
        }
        return quizzes;
    }

    function getSubmittedAnswer(address _user,uint _quizId) public view returns (uint8[QUIZ_LENGTH] memory){
      uint8[QUIZ_LENGTH] storage answers= userQuizSubmissionMapping[msg.sender][_quizId].answers;
      return answers;
    }

    function getUserQuizIds(address _user)public view returns (uint[] memory){
        return userQuizIdMapping[_user];
    }
}