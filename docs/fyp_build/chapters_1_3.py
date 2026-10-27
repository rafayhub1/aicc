"""Chapters 1 to 3."""

from styles import body, bullet, heading, page_break, table_caption, add_table


def add_chapter_1(document):
    heading(document, "Chapter 1  Introduction", 1)
    heading(document, "1.1  Background", 2)
    body(
        document,
        "A university campus is a small city with its own gates, timings, offices, and language. A new student learns it by asking. A returning student relearns it every semester when a class moves, a challan appears, or a consultation hour changes. Lahore Garrison University, in this project called LGU, already publishes much of that knowledge. The difficulty is not the absence of information. It is that the information does not travel with the student who is standing in a corridor with a question.",
    )
    body(
        document,
        "Mobile phones are already the tool students use for that question. Messaging a friend works until the friend is wrong. Searching the public web works until the answer is local. Opening a general chatbot works until the chatbot prefers a fluent sentence over a stored fact. Each of those habits is reasonable. Together they produce a daily tax of walking to the wrong block, missing a window at an office, or trusting a number that was never on a challan.",
    )
    body(
        document,
        "AICC, the AI Campus Companion, is a final-year system built for that tax. It is a Flutter application for the student and for a campus administrator, backed by a FastAPI service. The student can see stored academic facts, ask questions in ordinary language, and follow a walking route that includes paths inside the campus and, for a prepared building, paths between floors. The administrator can correct a place, a student record, or a notice without shipping a new application.",
    )
    heading(document, "1.2  The need this project addresses", 2)
    body(
        document,
        "Three needs sit on top of one another. The first is orientation. A visitor or a first-semester student can see the main gate and still not know which walkway leads to the Central Library, the LGU Cafe, or Classroom B-104. Public mapping services are strong on city roads. They are weak on the paved paths, lawns, and indoor stairs that actually join those places.",
    )
    body(
        document,
        "The second need is a trustworthy answer. Attendance rules, library hours, fee practice, and examination conduct are written down. A student should be able to ask in English or in Roman Urdu and receive the written rule, not a paraphrase that adds a fine or a deadline. When the question is personal, such as “what is my attendance?”, the answer must come from that student’s record. When the question is not in the handbook, the honest answer is to name the office that can confirm it.",
    )
    body(
        document,
        "The third need is one place to start. Fee challans, roll-number slips, teacher consultation hours, and campus notices already have homes. Students still hunt across screens. A companion does not replace the registrar or the portal. It gives a signed-in student a short path to the record that already exists, and a short path to the place named in that record.",
    )
    heading(document, "1.3  Aim", 2)
    body(
        document,
        "The aim of this project is to design and implement a campus companion that answers student questions from maintained data, shows the related place when one exists, and computes a walking route on the university’s own paths. The companion must remain usable when a language model is unavailable, because place lookup and personal records do not depend on one.",
    )
    heading(document, "1.4  Objectives", 2)
    bullet(document, "Provide a signed-in student dashboard for CGPA, current-semester courses, attendance, fee challans, and roll-number slips drawn from the campus record.")
    bullet(document, "Answer place questions from a maintained place list, including aliases, before any language model is called.")
    bullet(document, "Answer open handbook questions by retrieving passages and allowing a server-side model to phrase only those passages.")
    bullet(document, "Refuse questions that are outside the handbook, and never let the model invent a personal mark, a fee status, or a coordinate.")
    bullet(document, "Compute an outdoor walking route with Dijkstra on a published campus graph, and hand off to a public map when the student is outside the campus.")
    bullet(document, "Compute an indoor route with A* on a building graph, including stairs and lift, and explain the route as steps.")
    bullet(document, "Give an administrator tools to maintain students, teachers, notices, places, and indoor areas without an application update.")
    bullet(document, "Support English and Roman Urdu for place names and handbook questions, and keep the language-model key on the server.")
    heading(document, "1.5  Scope", 2)
    body(
        document,
        "The delivered scope is the Android application and the campus service that the application calls. Student features are sign-up and sign-in, the home dashboard, UniBot chat with voice input and spoken replies, chat history, notifications, a teacher directory, light and dark appearance, the outdoor campus guide, and the indoor floor map. Administrator features are a dashboard of counts, student and teacher maintenance, a broadcast, an activity log, place editing, walkway editing, QR codes for a start point, and indoor area editing.",
    )
    body(
        document,
        "The campus record used for demonstration covers three departments in the seed data, BS Computer Science, BS Psychology, and Bachelor of Business Administration, with sections and semesters sufficient to exercise the dashboard. Places include gates, the cafe, the library, the admin block, labs, and Classroom B-104, among others. Outdoor coordinates are a working sketch of the DHA Phase 6 campus and are meant to be replaced by a survey. Indoor geometry is a Block B demonstration building. Live bus tracking, hostel allocation, course registration itself, and official result publication stay outside the system. The assistant may explain where those tasks are done. It does not perform them.",
    )
    heading(document, "1.6  Intended users", 2)
    body(
        document,
        "The primary user is an enrolled student who already has, or can create, an application account tied to a registration number such as FA26-BSCS-001. That student may be new to the campus or may simply want a faster answer during the semester. The secondary user is a campus administrator who corrects records, publishes a notice, and keeps the place list aligned with the buildings people actually use. Teachers appear as profiles the student can search. They are not required to operate the application for the student scenarios in this report. A visitor who is not signed in is not a full user. Outdoor handoff to a public map is still available as a direction when a signed-in student is off campus.",
    )
    heading(document, "1.7  Significance", 2)
    body(
        document,
        "The practical significance is time and fewer wrong turns. A place card that opens the map, a route that follows internal walkways, and a document that opens from the same conversation remove a chain of separate searches. The academic significance is the separation of duties. Retrieval, a graph, and a student record each do the job they are good at. A language model is used where wording helps and is withheld where a wrong number would matter. That separation is the engineering contribution, more than any single screen.",
    )
    body(
        document,
        "There is also a maintenance significance. A new cafe alias, a changed library hour, or a moved classroom is a data change. The application does not need to be rebuilt for the place list or the handbook to move. This is why the project does not fine-tune a model on today’s campus facts. Fine-tuning would bury those facts inside weights that an administrator cannot edit on the day the hour changes.",
    )
    heading(document, "1.8  Assumptions and constraints", 2)
    bullet(document, "The student has an Android phone with a network connection for the first load of records. Place matching can then use the list already fetched.")
    bullet(document, "Registration numbers follow the campus pattern of intake, department code, and serial, and the department code must match the stored department.")
    bullet(document, "GPS inside a building is not treated as a reliable position. An indoor route starts from a chosen node or from a QR code at a door or stair.")
    bullet(document, "The language-model provider may be rate-limited or offline. Place answers, the dashboard, and graph routing must still function.")
    bullet(document, "Handbook text is an aid. It is not a substitute for a signed notice from the registrar, the examination office, or the department.")
    bullet(document, "Demonstration coordinates are not a surveyed map. Distance and time on the outdoor route are only as good as the graph an administrator publishes.")
    heading(document, "1.9  Outcome-based framing", 2)
    body(
        document,
        "This report is organised as an outcome-based final-year document. The problem is a complex computing problem in the ordinary sense used for such programmes: it crosses mobile interaction, information retrieval, graph search, security of credentials, and institutional data ownership. The requirements conflict. Students want a short answer, while the institution needs that answer to stay inside published rules. A single public map would be simpler and would miss internal paths. A single chatbot would be simpler and would be free to invent. The design in later chapters is the resolution of that conflict, not a catalogue of features.",
    )
    body(
        document,
        "No official programme-learning-outcome numbering is printed here, because that numbering belongs to the department’s current outcome map and should be attached by the supervisor at assessment. The objectives in Section 1.4 are written so that they can be mapped onto problem analysis, design, implementation, and evaluation without rewriting the system.",
    )
    heading(document, "1.10  Organisation of the report", 2)
    body(
        document,
        "Chapter 2 reviews campus assistants, grounded question answering, outdoor pedestrian graphs, and indoor positioning, and compares this project with a plain chatbot and with a public map alone. Chapter 3 states the problem, the stakeholders, and the success criteria. Chapter 4 is the software requirements specification: users, functions, quality requirements, interfaces, and use cases. Chapter 5 explains the method, the tools, and the routing and retrieval choices. Chapter 6 describes the architecture and the detailed design, including the required diagrams. Chapter 7 describes the implementation and the testing approach. Chapter 8 reports the checks that were defined and what they show, including the limits that remain. Chapter 9 concludes and lists future work.",
    )
    body(
        document,
        "This chapter has introduced the campus setting, the three needs of orientation, trustworthy answers, and a single starting place, and the boundary of what AICC will and will not do. The next chapter places those choices against published practice.",
    )


def add_chapter_2(document):
    page_break(document)
    heading(document, "Chapter 2  Literature Review", 1)
    heading(document, "2.1  Introduction", 2)
    body(
        document,
        "The companion sits at an intersection that already has a literature: university information systems, conversational question answering, pedestrian navigation, and indoor positioning. This chapter reads that literature only as far as it changes a design decision. A method is included when it was adopted, rejected, or kept as a boundary. The chapter closes with a comparison against the two alternatives a student would otherwise use, a general chatbot and a public map.",
    )
    heading(document, "2.2  Campus information systems", 2)
    body(
        document,
        "Universities have long separated the system of record from the system of conversation. Portals hold registration, attendance, and fees because those facts must be auditable. Notice boards and handbooks hold rules because those rules must be citable. Early campus applications often copied one of those stores onto a phone as a list. The list is reliable and silent. It does not help a student who can describe a need but cannot name the menu that holds it.",
    )
    body(
        document,
        "Later campus applications added search and, more recently, chat. The gain is that “where can I eat?” is a real question and “Food services” is an administrative category. The loss, documented across knowledge-intensive question answering, is that a generative model will answer even when the store has no passage. Lewis and colleagues showed that retrieval-augmented generation reduces this failure by conditioning the model on retrieved text rather than on the model’s memory alone [3]. That result is the reason AICC retrieves handbook passages before it asks a model to speak.",
    )
    body(
        document,
        "A second lesson from information systems is ownership. If the assistant is the only copy of a rule, the assistant becomes an ungoverned policy office. AICC therefore treats the handbook file and the student record as the sources. The chat text is a view. An administrator who changes a place or a record changes what the next question can say. This is closer to a maintained knowledge base than to a model trained once and frozen.",
    )
    heading(document, "2.3  Conversational assistants and invented answers", 2)
    body(
        document,
        "A large language model is a strong paraphraser and a poor ledger. It will produce a plausible attendance percentage, a plausible room, or a plausible fine because plausibility is what its training rewards. In a campus setting that behaviour is not a minor tone problem. A student may miss an examination or pay the wrong amount. The design response in the research literature is to ground the answer: retrieve, then generate, and decline when retrieval fails.",
    )
    body(
        document,
        "Grounding still fails if the retriever returns a near miss and the model treats it as a hit. BM25, the ranking function reviewed by Robertson and Zaragoza, scores a passage by how distinctive the shared words are, not by how fluent a later sentence could be [4], [6]. Embedding similarity catches a paraphrase that shares few exact words. AICC uses both scores. It also keeps a separate, non-generative path for questions whose answer is a place or a personal record. Those answers are lookups. Generation is the wrong tool, so it is not used.",
    )
    body(
        document,
        "Language is part of the same problem. Students at LGU ask in English, in Urdu script, and in Roman Urdu. A retriever that only tokenises English will miss “library kahan hai”. The handbook entries used by the service keep an English question, an Urdu question, and a Roman Urdu question beside one answer. Detection of script and of Roman markers chooses the wording of a refusal. The fact itself stays the stored sentence.",
    )
    heading(document, "2.4  Retrieval-augmented generation", 2)
    body(
        document,
        "Retrieval-augmented generation, usually shortened to RAG, splits an answer into a search step and a writing step. The search step is inspectable. A reviewer can see which passage was offered to the model. The writing step is where tone, length, and the student’s last few turns are handled. Lewis and colleagues introduced the pattern for knowledge-intensive tasks and showed gains when the model is allowed to read retrieved text at answer time. The campus service follows that pattern with a small, closed corpus: the student handbook, not the open web.",
    )
    body(
        document,
        "The closed corpus is a deliberate limit. Web search would answer “who won a cricket final” and would also answer campus questions with pages the university does not control. The system prompt used by the service tells the model to quote numbers, days, and fees as written, to stay within two to four sentences, and to say when no entry matched. If retrieval finds nothing, the spoken fallback names the Registrar or the relevant office. That sentence is also stored, in English, Urdu, and Roman Urdu, so the refusal is not itself generated from imagination.",
    )
    body(
        document,
        "Place cards are not left to the model. After an answer is planned, place identifiers are copied from the retrieved entry, or from a small food-word rule that points at the cafe. The model never chooses a latitude. This is stricter than generic RAG, and it is the right strictness for a map. A fluent sentence can be slightly loose. A pin cannot.",
    )
    heading(document, "2.5  Outdoor pedestrian navigation", 2)
    body(
        document,
        "Road navigation is a solved product for cities. It is the wrong product for a campus interior, because the fastest driving route is irrelevant and the pedestrian graph inside the gate is invisible to the city map. Campus wayfinding research therefore builds a local graph: gates, path junctions, and destinations, with edges that follow walkways rather than roads. Dijkstra’s algorithm computes a minimum-cost path on a graph with non-negative edge weights [1]. It is appropriate here because a walkway cost is a distance, and a distance is non-negative.",
    )
    body(
        document,
        "A public map remains the right product outside the gate. Re-implementing city routing would add a dependency and would still be worse than the product students already trust on roads. The design boundary is geographic. Inside a published campus outline, AICC routes on its graph. Outside it, the application opens a walking link toward the nearest gate. The student is not asked to understand that split. The session simply changes tool.",
    )
    body(
        document,
        "Cost quality depends on the survey. An edge with a measured length is an honest cost. An edge with a missing length must still allow a path, or the graph breaks the day an administrator adds a node and forgets a metre value. The outdoor router uses a fallback of 25 metres and marks the route as estimated. The mark matters. A confident time built on a placeholder would repeat the chatbot failure in another form.",
    )
    heading(document, "2.6  Indoor positioning and floor-plan navigation", 2)
    body(
        document,
        "Indoor positioning surveys, including the review by Zafari, Gkelias, and Leung, catalogue radio maps, inertial sensors, magnetic fingerprints, and visual methods [5]. All of them can work in a prepared building. All of them need a survey, calibration, and a tolerance for drift. GPS, which students already have, is regularly poor indoors because the satellite signal is blocked or reflected. A navigation feature that trusts that signal between two classrooms will draw the student through walls.",
    )
    body(
        document,
        "This project rejects live radio positioning for the first delivery. The building is represented as floors, rooms, and a navigation graph in local metres. A stair or a lift is an edge with a floor-change cost, not a guessed vertical GPS jump. The student’s start is a node they choose, or a QR code posted at a door or stair that names the node. QR positioning is coarse. It is also understandable, cheap, and stable. The student can see the code that set their start. A radio fingerprint cannot be shown in the same way.",
    )
    body(
        document,
        "Floor drawings in the demonstration are a sketch of Block B. Official architectural sheets were not cleared for inclusion. The graph, not the picture, is what the router trusts. A later replacement of the picture does not require a new algorithm if the nodes stay tied to doors and junctions. That split, picture for the eye and graph for the route, is the indoor design.",
    )
    heading(document, "2.7  Graph search for wayfinding", 2)
    body(
        document,
        "Dijkstra’s algorithm expands the closest unsettled node until the goal is settled. It is optimal for non-negative costs and it does not need a heuristic. A*, introduced by Hart, Nilsson, and Raphael, uses a heuristic that estimates the remaining cost [2]. When the heuristic never overestimates, A* is also optimal and usually expands fewer nodes. On a building floor the straight-line distance in local metres is such a heuristic, because a person cannot walk shorter than the straight line and may have to walk longer around rooms.",
    )
    body(
        document,
        "The indoor router implements both. The student path uses A*. A zero heuristic reduces the same code to Dijkstra, which is kept so tests can compare the two searches on one graph. Preferences are costs, not a second algorithm. Preferring stairs adds a penalty to lift edges. A stair flight adds a per-floor cost larger than a lift stop, so the default path takes the lift when both exist, and the student can still ask for stairs. Turn instructions ignore small heading changes so a gently bent corridor does not become a list of tiny turns.",
    )
    heading(document, "2.8  Mobile structure relevant to this system", 2)
    body(
        document,
        "The application is a client of two stores. One store is the campus service: records, places, indoor maps, and chat. The other is a mobile Firebase project: authentication, chat transcripts, faculty profiles, and activity. This split follows a common mobile pattern. Authentication and private user documents want a vendor SDK with rules. Shared campus facts want an HTTP API the same administrator can also open in a browser. Putting the language-model key in the phone would make every installed copy a credential. The key stays in the service environment.",
    )
    body(
        document,
        "State on the phone is intentionally small. A session object holds the signed-in student. Screens ask repositories for lists. Routing is a pure function of a graph and two identifiers. That purity is why the outdoor and indoor routers can be tested without a device. Widget tests cover the screens that must show a banner when location is denied or a card when a place matches. The literature on testable architecture is simply applied here. The algorithm is not mixed into the widget that paints the line.",
    )
    heading(document, "2.9  Comparison with existing approaches", 2)
    body(
        document,
        "Table 2.1 compares AICC with the two approaches a student can already attempt, and with a radio-based indoor system of the kind surveyed in the positioning literature. The comparison is about fit to this campus problem, not about which technology is generally superior.",
    )
    table_caption(document, "Table 2.1  Comparison of AICC with nearby alternatives")
    add_table(
        document,
        ["Need", "General chatbot", "Public map alone", "Radio indoor positioning", "AICC"],
        [
            ["Place pin", "May invent a place", "City pin, not a room", "Needs a surveyed radio map", "Stored place list and node"],
            ["Handbook rule", "May invent a number", "Does not answer", "Does not answer", "Retrieved passage, then a short wording"],
            ["Personal CGPA", "Must not be guessed", "Does not answer", "Does not answer", "Read from the student record"],
            ["Path inside campus", "Text only", "Roads outside the paths", "Not a campus graph", "Dijkstra on published walkways"],
            ["Path indoors", "Text only", "GPS is weak indoors", "Possible, costly to maintain", "A* on a floor graph, QR start"],
            ["Update a fact", "Retrain or hope", "Vendor map update", "New survey", "Edit the record or the place"],
            ["Key safety", "Key often in the client", "Vendor account", "Local sensors", "Model key only on the server"],
        ],
    )
    heading(document, "2.10  Summary", 2)
    body(
        document,
        "Published practice supports four decisions taken in this project. Answers about rules should be retrieved before they are phrased. Answers about places and personal records should not be phrased by a model at all. Outdoor campus paths need a local graph, while city roads can stay with a public map. Indoor position for a first delivery should be a visible start node, not a fragile GPS fix. Chapter 3 turns those decisions into a problem statement and a set of success criteria.",
    )


def add_chapter_3(document):
    page_break(document)
    heading(document, "Chapter 3  Problem Definition", 1)
    heading(document, "3.1  Problem statement", 2)
    body(
        document,
        "An LGU student who needs a place, a rule, or a personal document must today assemble the answer from several sources that do not know about each other. The public map does not contain the internal walkway. A general chatbot does not contain today’s challan. The handbook does not open the map at the library it mentions. The result is delay, wrong turns, and answers that sound official without being stored anywhere an office can correct.",
    )
    body(
        document,
        "The problem, stated as an engineering task, is to provide one mobile companion that (1) reads personal academic facts only from the campus record, (2) answers institutional questions only from a maintained handbook, (3) resolves a named place only from a maintained list, and (4) computes a walk on a graph the campus can edit, indoors and outdoors, handing city roads back to a public map. The companion must keep doing (1), (3), and (4) when the language model is unavailable.",
    )
    heading(document, "3.2  Stakeholders", 2)
    body(
        document,
        "Students need short, checkable answers and a route they can follow between classes. Administrators need to correct a place, a notice, or a student row without a developer. Faculty need their consultation hours to be findable, without being asked to chat on the student’s behalf. The department needs a final-year system that can be demonstrated, tested, and explained. The registrar and examination offices are indirect stakeholders: the assistant must not speak for them beyond the text they have already issued. Families and visitors appear only as people a student might guide. They do not receive accounts in this version.",
    )
    heading(document, "3.3  The situation the project starts from", 2)
    body(
        document,
        "Before this system, a student with a place question asked a classmate or followed a city map to the gate and then guessed. A student with a rule question searched old messages or a PDF. A student with a challan question opened a portal if they remembered the path. None of these steps is broken on its own. The failure is the gap between them. There is no shared place identifier that a sentence and a map can both use. There is no rule that says a generated sentence may not contain a CGPA. There is no published walkway graph for the paths between the Main Gate, the South walk, the library, and Block B.",
    )
    body(
        document,
        "The project also starts from a data constraint. Official floor plans were not available for redistribution, and a full GPS survey of every path was not completed during development. Any definition of the problem that required centimetre-accurate blueprints before a route could be shown would have produced no system. The problem definition therefore separates the algorithm, which can be correct on a sketch, from the survey, which must replace the sketch before the distances are treated as operational.",
    )
    heading(document, "3.4  Gaps", 2)
    bullet(document, "No single student-facing flow joins a question, a stored place, and a walking route.")
    bullet(document, "No guard stops a language model from inventing a room, a fee, or a mark.")
    bullet(document, "No campus-owned graph describes internal walkways, stairs, and lifts.")
    bullet(document, "No administrator path updates that graph or the handbook without an application release.")
    bullet(document, "Place questions in Roman Urdu are not first-class in a typical English-only map search.")
    bullet(document, "Indoor GPS is trusted by habit and is not reliable enough to start a corridor route.")
    heading(document, "3.5  Proposed solution", 2)
    body(
        document,
        "The proposed solution is the companion described in Chapter 1, specified in Chapter 4, and designed in Chapter 6. On the phone, an intent step decides whether the utterance is a greeting, a document request, a personal academic question, a faculty question, a place question, or an open question. Place questions resolve against aliases. Personal facts are loaded from the signed-in student. Open questions go to the service, which retrieves handbook passages and only then calls Groq. Outdoor routing runs Dijkstra on published connections. Indoor routing runs A* with stair and lift costs. An administrator edits the same records the student reads.",
    )
    body(
        document,
        "The solution is intentionally boring at the points where boredom is safety. A place card is a record. A route is a list of nodes. A CGPA is a stored field on a four-point scale. The language model is allowed to be interesting only inside a passage the retriever already selected.",
    )
    heading(document, "3.6  Success criteria", 2)
    bullet(document, "A known place name, including a longer name and a cafe alias such as canteen, returns that place’s card and no invented coordinate.")
    bullet(document, "A handbook question returns the stored rule, and a question outside the handbook is refused without a place card.")
    bullet(document, "A food question may attach the cafe card because the passage or the food rule already names that place.")
    bullet(document, "Personal attendance and CGPA on the dashboard match the campus record and are not recomputed by the model.")
    bullet(document, "An on-campus direction produces an in-application route. An off-campus direction opens a public walking link toward a gate.")
    bullet(document, "An indoor route from a QR or a chosen start reaches the room and can prefer stairs or the lift.")
    bullet(document, "An administrator can add a place and see it on the student map after save, without an application update.")
    bullet(document, "The model key is not present in the mobile application.")
    body(
        document,
        "These criteria are checked in Chapters 7 and 8. A surveyed metre error for outdoor GPS is not a success criterion of this delivery, because the evaluation log for that error was left blank pending a campus survey. Treating a blank as a pass would be a false result.",
    )
    heading(document, "3.7  Summary", 2)
    body(
        document,
        "The problem is the gap between stored campus facts and the student who needs them while walking. The proposed system closes that gap with lookups, retrieval, and two graphs, and it refuses to close it with invention. Stakeholders, gaps, and success criteria are now fixed. Chapter 4 turns the criteria into requirements a design can be checked against.",
    )
