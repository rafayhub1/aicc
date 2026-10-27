"""Chapter 6, design and diagrams."""

from styles import add_figure, add_table, body, bullet, caption, heading, page_break, table_caption


def _fig(document, path, text, width=6.3):
    add_figure(document, path, width=width)
    caption(document, text)


def add_chapter_6(document, figures):
    page_break(document)
    heading(document, "Chapter 6  Detailed Design and Architecture", 1)
    heading(document, "6.1  System architecture", 2)
    body(
        document,
        "The system is partitioned by who is allowed to decide. The phone decides what a tap means, which place name matched, and which path to draw. The campus service decides which handbook passage is relevant and how a model may phrase it. The stores decide what is true. A language model is not a store. This section names the parts and the reason for the cut. The diagrams that follow are the same cut drawn as structure, behaviour, and data.",
    )
    heading(document, "6.1.1  Architecture design approach", 3)
    body(
        document,
        "The approach is a layered client plus a small set of HTTP capabilities, with two deliberately different data homes. A single database for chat transcripts and official student rows would have mixed a private mobile account with records an administrator edits in bulk. A single on-phone database for the handbook would have made every rule change an application update. The rejected alternative of calling the model directly from Flutter was dropped because the key would ship inside the application and because the phone would be free to skip retrieval.",
    )
    body(
        document,
        "A second rejected cut was one router for indoors and outdoors. The coordinates differ. Outdoor nodes are latitude and longitude. Indoor nodes are local metres on a floor. Forcing one graph would hide floor changes inside fake outdoor edges. The systems share a place identifier and a habit of explicit edges. They do not share a coordinate type. A third rejected cut was inferring indoor edges by proximity. Two points can be close across a wall. An edge exists only when an author joins the point just placed to the previous point, or otherwise writes the edge. The wall stays a wall.",
    )
    heading(document, "6.1.2  Architecture design", 3)
    body(
        document,
        "Figure 6.3 shows four bands. The Flutter application paints screens and holds the session. The on-phone decision layer classifies utterances and runs both routers. The FastAPI service exposes records, places, indoor maps, chat, and admin operations. Beneath it sit mobile Firebase, campus records, Groq, and the public map used only off campus. Arrows point downward because a lower band does not call a widget. The phone never receives the model key. The service never paints a route. The map package never decides a handbook sentence.",
    )
    _fig(document, figures["architecture"], "Figure 6.3  System architecture")
    body(
        document,
        "Collaboration is short. A dashboard load reads the signed-in registration number and calls the student and course endpoints. A place question does not leave the phone when the list already contains the name. An open question posts the text and at most a few previous turns. The reply is text plus place identifiers, which the phone turns into cards from the same place list. A direction request either runs a local router or opens a public walking URL. An administrator save writes a place or an indoor area. The next student fetch sees it. Nothing in that chain requires a store procedure hidden from the diagram.",
    )
    heading(document, "6.1.3  Subsystem architecture", 3)
    body(
        document,
        "Table 6.1 names the subsystems used in the rest of this chapter. Figure 6.6 draws the same split as components. Figure 6.9 is the context data flow: the student sends a question or a location and receives an answer or a route; the administrator sends places and notices; the stores sit beside the process rather than inside the actors.",
    )
    table_caption(document, "Table 6.1  Subsystem responsibilities")
    add_table(
        document,
        ["Subsystem", "Responsibility", "Does not do"],
        [
            ["Student shell", "Navigation, theme, session, push entry", "Route search or handbook ranking"],
            ["UniBot", "Classify, call chat, show cards, speak and listen", "Invent a place id"],
            ["Campus guide", "Map, outdoor Dijkstra, QR start, off-campus handoff", "Indoor floor geometry"],
            ["Indoor map", "Floors, A*, instructions, stair or lift preference", "City routing"],
            ["Admin console", "Students, teachers, broadcast, places, indoor edits", "Student chat history"],
            ["Campus service", "Validation, retrieval, Groq, admin checks", "Drawing the map"],
            ["Stores", "Identity, records, graphs, transcripts", "Choosing a sentence"],
        ],
    )
    _fig(document, figures["component"], "Figure 6.6  Component diagram")
    _fig(document, figures["dfd"], "Figure 6.9  Context data-flow diagram", width=6.2)

    heading(document, "6.2  Detailed system design", 2)
    body(
        document,
        "The template asks each major component for its kind, purpose, responsibilities, constraints, composition, interactions, resources, processing, and interface. Table 6.2 records those attributes for the six parts that carry the engineering risk. The narratives after the table expand the processing of conversation, outdoor routing, and indoor routing, which are the parts a reviewer will trace by hand. Screen widgets that only arrange text are not repeated. Their behaviour is the requirement row they implement.",
    )
    table_caption(document, "Table 6.2  Design attributes of the main components")
    add_table(
        document,
        ["Component", "Kind", "Purpose", "Constraint", "Uses"],
        [
            ["Flutter client", "Application", "All student and admin interaction", "No model key; Android first", "Service, Firebase, map tiles"],
            ["Intent and place match", "Pure functions", "Choose a path before generation", "Longer place name wins", "Place list, local rules"],
            ["Campus service chat", "HTTP module", "Retrieve, then phrase", "Two to four sentences; quote figures", "Handbook, Groq"],
            ["Campus router", "Pure function", "Outdoor minimum path", "Published edges; 25 m fallback", "Campus graph"],
            ["Indoor router", "Pure function", "Indoor minimum path", "Explicit edges; cost table", "Building graph"],
            ["Record stores", "Documents", "Facts the UI may state", "Student sees own row", "Firestore through rules and the service"],
        ],
    )
    heading(document, "6.2.1  Classification", 3)
    body(
        document,
        "The client is an application. Intent, both routers, and the handbook ranker are pure modules: the same inputs give the same outputs and they do not read the clock or the network. The chat HTTP module, the student API, and the admin API are service modules with credentials and side effects. Firestore collections and the handbook file are data modules. Widgets are views. Keeping the pure modules free of widgets is what makes Table 7.1 possible on a desktop test run.",
    )
    heading(document, "6.2.2  Definition", 3)
    body(
        document,
        "The client is the signed-in face of FR-01 through FR-25. Intent is the definition of FR-05 through FR-07. The chat module is the definition of FR-08 through FR-11. The campus router is FR-15 through FR-17. The indoor router is FR-18 through FR-20. The stores are the definition of NFR-01: if a fact is not in a store, the interface may not state it. This mapping is the trace from Chapter 4 into design. A component without a requirement identifier was not added to carry the core path.",
    )
    heading(document, "6.2.3  Responsibilities", 3)
    bullet(document, "The client collects input, shows loading and errors, and starts the correct pure function or request.")
    bullet(document, "Intent returns one class and, for a place, one identifier. It does not call the network.")
    bullet(document, "The chat module returns text and a list of place identifiers that already existed on passages or on the food rule.")
    bullet(document, "The campus router returns an ordered node list, instructions, a distance, and an estimated flag, or an empty route.")
    bullet(document, "The indoor router returns a ready route, an unknown node, or no route. Instructions are a second step on a ready route.")
    bullet(document, "Stores persist the fields in Section 4.7 and reject a registration number that disagrees with the department.")
    heading(document, "6.2.4  Constraints", 3)
    body(
        document,
        "Intent must run on the UI isolate without a visible stall on a few dozen places. The chat history sent upward is capped, in the service model, at six turns, and each turn is shortened again before it is placed in the prompt. Audio shorter than a small threshold is rejected as a tap rather than speech. Audio above a few megabytes is rejected. Admin calls without the administrator credential fail. Indoor search treats a missing node as an unknown-node result, not as a crash. Outdoor search treats a disconnected goal as an empty route. A route that used a fallback length must set the estimated flag. These constraints are also the exception columns of the use cases.",
    )
    heading(document, "6.2.5  Composition", 3)
    body(
        document,
        "The client is composed of the shell, feature screens, repositories, and the pure modules above. The indoor feature is itself a composition: entities for the building, a graph builder, the router, route costs, an instruction builder, a geographic converter, a validator, and a map controller that the floor painter observes. The service is composed of routers for students, courses, documents, notifications, statistics, places, indoor maps, chat, and admin, plus handbook ranking, the Groq client, and Firebase access. The handbook file is not compiled into the phone.",
    )
    heading(document, "6.2.6  Uses and interactions", 3)
    body(
        document,
        "Figure 6.4 is the activity of one question. Figure 6.5 is the sequence when the question is a place and then a follow-up about hours. The phone asks intent first. A place hit returns to the student as a card and never reaches Groq. A later hours question misses the place-only path, is posted to the service, and is retrieved before the model sees it. Figure 6.7 is the life of a route after the student asks for directions. Idle becomes locating, then routing, then on route, then arrived. Leaving the corridor beyond the off-route distance returns to routing. End or cancel finishes the session. Off campus, the transition from locating does not enter routing on the campus graph at all.",
    )
    _fig(document, figures["activity"], "Figure 6.4  Activity diagram for a campus question", width=4.6)
    _fig(document, figures["sequence"], "Figure 6.5  Sequence diagram for a grounded answer")
    _fig(document, figures["state"], "Figure 6.7  Navigation state machine")
    heading(document, "6.2.7  Resources", 3)
    body(
        document,
        "The phone needs memory for the place list, the active graph, and the decoded floor image. It needs the network for the first fetch and for chat, the microphone for voice, the camera for QR, and location only for outdoor start. The service needs the handbook file, an embedding cache warmed at startup when the file loads, a Firestore client, and the Groq credential. There is no lock shared between a student’s route computation and an administrator’s save. A save is visible on the next read. The route already on screen is a snapshot, which avoids a deadlock between a painter and a writer. Push delivery depends on the platform messaging service and is allowed to arrive late. The inbox still loads from the record.",
    )
    heading(document, "6.2.8  Processing", 3)
    body(
        document,
        "Outdoor processing is Dijkstra, as described in Section 5.4. Indoor processing builds the graph, seeds a binary heap with the start, and expands the lowest f-score. The g-score is the cost from the start. The heuristic is straight-line distance when A* is requested and zero when Dijkstra is requested. A stale heap entry, whose g is worse than the best already stored, is skipped. When the goal is dequeued, predecessors are walked back to the start. Equal f-scores break ties by insertion order so two runs on the same building match. The result is then walked by the instruction builder, which groups a straight corridor, emits a floor-change sentence when the floor id changes, and ends with the room name.",
    )
    body(
        document,
        "Retrieval processing tokenises the question, scores every handbook entry with BM25 and with cosine similarity, and keeps the leading passages. Language detection looks for Urdu script and for Roman Urdu markers so a refusal can be worded in the language of the question. The model call is a chat completion with a system instruction, the passages, and a short history. A thinking block, if the model emits one, is stripped before the text returns to the phone. Place identifiers are computed from the plan, not from that text.",
    )
    body(
        document,
        "Neither search is expensive at the demonstration size. Dijkstra on a campus of a few dozen nodes is negligible beside a map tile. A* on one building with a few floors is negligible beside painting the floor. The scalability requirement is therefore about data growth, not about a new algorithm at a thousand nodes. A later campus-wide indoor graph would still be sparse. The heap implementation is the ordinary logarithmic one and does not need replacement for the university’s buildings.",
    )
    heading(document, "6.2.9  Interface and exports", 3)
    body(
        document,
        "The outdoor router exports one function from a graph and two node identifiers to a route value. The indoor router exports route and dijkstra, each taking a building, two node identifiers, and a preference. The intent function exports a class and an optional place identifier. The chat endpoint exports text and place identifiers. Student endpoints export the record, courses for a semester, notifications, and documents. Place endpoints export the active list to students and the editable list to administrators. None of these exports includes a free-form coordinate produced by the model. Clients that need a pin read the place.",
    )
    heading(document, "6.2.10  Detailed subsystem design", 3)
    heading(document, "6.2.10.1  Use cases", 3)
    body(
        document,
        "Figure 6.1 places the student on the left of the system boundary and the administrator on the right. The student’s cases are the daily path: sign in, dashboard, question, document, outdoor route, indoor route, teacher, and notices. The administrator’s cases are maintenance: people, places, broadcast, and indoor areas. A student does not have a line to publish a place. An administrator does not have a line to the student’s private chat. Shared data crosses inside the boundary, through the stores, not through a shared screen.",
    )
    _fig(document, figures["usecase"], "Figure 6.1  Use-case diagram")
    heading(document, "6.2.10.2  Information model", 3)
    body(
        document,
        "Figure 6.2 is the entity-relationship view. A student enrols in courses, receives notifications, and owns documents. A place links to a walkway node. Nodes join through connections. A building contains floors. A floor contains rooms. An application account owns chat sessions. The relationship names are the ones the API actually enforces. There is no relationship from a generated sentence to a coordinate. Figure 6.10 draws the same facts as two databases. Figure 6.8 is the class view of the navigation model the phone holds in memory while routing.",
    )
    _fig(document, figures["er"], "Figure 6.2  Entity-relationship diagram")
    _fig(document, figures["class"], "Figure 6.8  Class diagram of the navigation model")
    _fig(document, figures["database"], "Figure 6.10  Database diagram")
    body(
        document,
        "The mobile database holds users, chat sessions, chat messages, faculty, and activity events. The campus database holds students, with courses, notifications, and documents nested under the registration number, plus places, the walkway graph, and indoor maps. Nesting courses under the student matches the access rule: a read of courses is always a read for one student. The handbook is a file on the service. It is versioned with the software that understands its headings, and it is not writable from the student application. That is a constraint, not an omission. A student-writable handbook would make NFR-01 unenforceable.",
    )
    heading(document, "6.2.10.3  Indoor class responsibilities", 3)
    body(
        document,
        "Building stores the origin and the entrance node used when the student has not chosen a start. Floor stores the level integer so a stair cost can be the absolute difference in levels. Room stores a polygon for paint and a door point for the last step of an instruction. NavNode stores local x and y, growing east and north before the building rotation is applied, and an optional link. IndoorRouter does not store the building. It receives one. RouteCosts is a value object so a test can construct a router with exaggerated stair costs and prove the lift is chosen, or the reverse. CampusPlace is the outdoor twin: aliases and a node identifier, no polygon.",
    )
    body(
        document,
        "The geographic converter applies the origin and rotation when a local point must be shown on the earth, or the reverse when a QR payload is a geographic hint. The validator checks that edges refer to known nodes and that a floor link points at a real node. A building that fails validation is not routed. The map controller holds the selected floor, the active route, and the preference, and it notifies the painter. The painter does not search.",
    )
    heading(document, "6.2.10.4  Failure behaviour", 3)
    body(
        document,
        "Each subsystem has a visible failure. A waking host shows a banner rather than an infinite spinner with no words. A chat refusal names an office. An empty outdoor route does not become a straight line. An unknown indoor node names the identifier that failed. A pending document does not pretend to be a file. A denied location permission explains the “I’m at” list. These behaviours are designed, because a blank failure is how a student ends up trusting a guess from somewhere else.",
    )
    heading(document, "6.3  Summary", 2)
    body(
        document,
        "The architecture separates interaction, decision, wording, and truth. The diagrams in this chapter are those separations drawn as use cases, entities, layers, an activity, a sequence, components, route state, classes, a context flow, and two databases. Chapter 7 describes how the separations were implemented and how they are tested.",
    )
