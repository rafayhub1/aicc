"""Chapters 4 and 5."""

from styles import add_table, body, bullet, heading, page_break, table_caption


def add_chapter_4(document):
    page_break(document)
    heading(document, "Chapter 4  Software Requirement Specification", 1)
    heading(document, "4.1  Introduction", 2)
    body(
        document,
        "This chapter specifies what AICC must do and the qualities it must keep while doing it. Requirements are written so that a later design decision can be traced to a sentence. Identifiers are stable: FR for a function, NFR for a quality, and UC for a use case. The specification describes the system that was built. It does not list live bus tracking or hostel booking, which were considered and left out.",
    )
    heading(document, "4.2  Product perspective", 2)
    body(
        document,
        "AICC is a new companion beside existing university offices and the public map. It does not replace the student portal’s registration workflow, the examination gazette, or Google Maps on city roads. It depends on a campus HTTP service, on Firebase Authentication and Cloud Firestore for the mobile project, on Firebase Cloud Messaging for push notices, and on Groq for handbook wording and for speech-to-text. If the campus service is asleep on a free hosting tier, the phone shows a waking state and retries with a longer timeout. The product must degrade to stored place answers and stored records rather than blocking the whole application on the model.",
    )
    heading(document, "4.3  User classes", 2)
    body(
        document,
        "Two people operate the system. Their responsibilities do not overlap, and the phone sends an administrator to a different shell after sign-in.",
    )
    table_caption(document, "Table 4.1  User classes and responsibilities")
    add_table(
        document,
        ["User", "Goal", "Must not do"],
        [
            ["Student", "Read own record, ask questions, follow routes, open notices", "Edit another student, publish a place, see the model key"],
            ["Administrator", "Maintain students, teachers, places, indoor areas, and broadcasts", "Receive generated academic advice as if it were policy"],
        ],
    )
    heading(document, "4.4  Functional requirements", 2)
    body(
        document,
        "Table 4.2 lists the functions the delivered system implements. Each row is testable by a screen action or by an automated test named in Chapter 7.",
    )
    table_caption(document, "Table 4.2  Functional requirements")
    add_table(
        document,
        ["ID", "Requirement"],
        [
            ["FR-01", "The system shall create a student account with email and password and bind it to a registration number."],
            ["FR-02", "The system shall keep the session until the student signs out, and shall open the admin shell when the account is an administrator."],
            ["FR-03", "The home screen shall show the stored CGPA, the current-semester courses, and the average attendance of those courses."],
            ["FR-04", "The student shall open a fee challan or roll-number slip when the document status is ready."],
            ["FR-05", "UniBot shall classify greetings, document requests, personal academics, faculty questions, place questions, and unknown questions."],
            ["FR-06", "A place question shall match the maintained list, preferring a longer name, and shall return that place’s card."],
            ["FR-07", "Aliases such as canteen for the LGU Cafe, and Roman Urdu place phrases, shall resolve to the same card."],
            ["FR-08", "An open question shall be sent to the campus service, which retrieves handbook passages before calling the model."],
            ["FR-09", "The model shall not be given the task of inventing attendance, CGPA, document status, or a teacher’s live location."],
            ["FR-10", "A question outside the handbook shall be refused, and no place card shall be attached unless a passage or a food rule already has a place id."],
            ["FR-11", "The student shall speak a question. The service shall transcribe the audio. The phone shall be able to speak the reply."],
            ["FR-12", "Chat sessions shall be listed, replayed, and deleted."],
            ["FR-13", "Notifications shall merge campus notices with push messages, and a notice shall be markable as read."],
            ["FR-14", "The student shall search faculty and open a profile with consultation hours."],
            ["FR-15", "The campus map shall search places and draw a Dijkstra route on published walkways while the student is inside the campus."],
            ["FR-16", "If the student is outside the campus, directions shall open a public walking link toward the nearest gate."],
            ["FR-17", "If location permission is denied, the map shall explain that and offer an “I’m at” list when directions start."],
            ["FR-18", "A QR code shall set the indoor or campus start node."],
            ["FR-19", "The indoor map shall route with A* between nodes, change floors by stairs or lift, and list turn instructions."],
            ["FR-20", "The student shall prefer stairs or allow either connector. Costs shall follow the published route-cost table."],
            ["FR-21", "An administrator shall create, edit, and remove students, including courses, notices, and documents belonging to that student."],
            ["FR-22", "An administrator shall maintain teacher profiles, broadcast a notice, and read an activity log."],
            ["FR-23", "An administrator shall add a place by a pin, edit aliases and the linked graph node, and publish or hide it."],
            ["FR-24", "An administrator shall edit indoor areas as named points and edges that do not jump through a wall merely because two points are close."],
            ["FR-25", "The phone shall offer light and dark appearance and shall show an empty, loading, or error state instead of a blank screen."],
        ],
    )
    heading(document, "4.5  Non-functional requirements", 2)
    table_caption(document, "Table 4.3  Non-functional requirements")
    add_table(
        document,
        ["ID", "Quality", "Requirement"],
        [
            ["NFR-01", "Grounding", "A coordinate, a CGPA, a fee status, or an attendance figure shown as fact shall come from a store, not from model text."],
            ["NFR-02", "Security", "The Groq key shall remain in the service environment. Admin routes shall require an administrator credential."],
            ["NFR-03", "Privacy", "A student shall read their own courses, documents, and chat, not another student’s."],
            ["NFR-04", "Availability", "Place match, dashboard cache behaviour, and on-phone routing shall not require the model to be up."],
            ["NFR-05", "Performance", "Place match and a campus route on the demonstration graph shall complete on the phone without a visible wait beyond a tap."],
            ["NFR-06", "Scalability", "Adding a place or a handbook passage shall be a data change. The search algorithms shall not be rewritten for each new room."],
            ["NFR-07", "Usability", "Touch targets, typed forms, and a waking-server message shall keep the first request after an idle host understandable."],
            ["NFR-08", "Maintainability", "Routers and intent classification shall be pure enough to unit test without a device."],
            ["NFR-09", "Language", "Place names and handbook questions shall be usable in English and Roman Urdu. Urdu script shall be recognised for handbook wording."],
            ["NFR-10", "Honesty of estimates", "A walkway edge with no measured length shall use a fallback and the route shall be marked estimated."],
            ["NFR-11", "Portability", "The student application targets Android through Flutter. The service is ordinary HTTP and can move host."],
            ["NFR-12", "Audit", "Administrative broadcasts and sign-in related activity shall be recordable in an activity log."],
        ],
    )
    heading(document, "4.6  External interface requirements", 2)
    heading(document, "4.6.1  User interface", 3)
    body(
        document,
        "The student interface is a shell with Home, UniBot, History, Notifications, and Teachers, plus the campus guide and the indoor map reached from a place or from navigation. The visual language uses the university navy, the Inter typeface, cards with a small radius, and a pill-shaped primary action. Loading uses skeletons. An empty list explains what is missing. An error offers retry. The administrator interface is a separate shell: Dashboard, Students, Teachers, Broadcast, and Activity, with place and indoor tools reached from campus maintenance. Both shells share appearance settings.",
    )
    heading(document, "4.6.2  Software interfaces", 3)
    body(
        document,
        "The phone calls the campus service over HTTPS. The base address defaults to the deployed host and can be overridden on the device for a local demonstration. Student reads include the catalogue, one student, that student’s courses, notifications, and documents. Chat posts a message and a short history and receives text plus place identifiers. A separate upload transcribes audio. Place and indoor-map routes serve the graphs. Admin routes require an administrator header and cover passwords, deletion, broadcast, and activity. The phone also uses Firebase Authentication, Firestore listeners for places and chat where configured, and Firebase Cloud Messaging. Outdoor tiles come from a map package. Off-campus walking uses the platform URL launcher.",
    )
    heading(document, "4.6.3  Hardware and communication", 3)
    body(
        document,
        "The student device needs a network radio, a screen, and, for spoken questions, a microphone. Location is requested for outdoor routing and is not required to ask a handbook question. The camera is used by the QR scanner. The service needs outbound access to Firestore and to the Groq HTTPS endpoint. No special campus radio infrastructure is required.",
    )
    heading(document, "4.7  Data requirements", 2)
    body(
        document,
        "A student row stores name, registration number, department code, semester, section, and overall CGPA. The registration number is the document identity. Courses store a code, a name, an attendance percentage, and a semester. Notifications store a type, a message, a read flag, and a timestamp. Documents store a type of fee challan or roll-number slip, a status of pending or ready, and an optional file address. A place stores an identifier, a display name, aliases, a category, coordinates, an optional entrance, building and floor text, hours, a description, a photo address, a graph node identifier, and an active flag. The outdoor graph stores nodes and connections. A connection may be one-way or two-way and may carry a distance and an instruction. An indoor building stores an origin, floors, rooms, nodes, and edges. Stair and lift nodes may link to another floor. Chat transcripts store sessions and messages under the mobile account. Faculty profiles store the fields needed for search and consultation hours.",
    )
    body(
        document,
        "Validation rules that protect the data are part of the requirement. A registration number has three parts and the department code inside it must equal the department field. CGPA lies between 0 and 4. Attendance lies between 0 and 100. Place identifiers are lowercase machine names. The model is not a writer of these fields.",
    )
    heading(document, "4.8  Use cases", 2)
    body(
        document,
        "Table 4.4 catalogues the use cases drawn in Figure 6.1. The main success path is described. Exceptions that the system must handle are named in the same row.",
    )
    table_caption(document, "Table 4.4  Use-case catalogue")
    add_table(
        document,
        ["ID", "Name", "Actor", "Success", "Exceptions"],
        [
            ["UC-01", "Sign in", "Student", "Session opens on Home", "Unknown account, wrong password, service waking"],
            ["UC-02", "View dashboard", "Student", "CGPA, courses, attendance shown", "No courses, service error with retry"],
            ["UC-03", "Open a document", "Student", "Ready challan or slip opens", "Status still pending"],
            ["UC-04", "Ask a place", "Student", "Place card, then map", "Unknown place falls through to handbook"],
            ["UC-05", "Ask a rule", "Student", "Handbook answer", "No passage: office refusal, no fake card"],
            ["UC-06", "Ask something personal", "Student", "Recorded attendance or CGPA", "Model is not asked to invent it"],
            ["UC-07", "Speak a question", "Student", "Transcript then the same router", "Clip too short or too long"],
            ["UC-08", "Outdoor directions", "Student", "On-campus polyline and steps", "Off campus opens public map; location denied shows a start list"],
            ["UC-09", "Indoor directions", "Student", "Floor route and step list", "No path; unknown node"],
            ["UC-10", "Find a teacher", "Student", "Profile and hours", "No match"],
            ["UC-11", "Read notices", "Student", "List, mark read, open from push", "Empty inbox"],
            ["UC-12", "Maintain students", "Administrator", "Create or edit a valid row", "Registration does not match department"],
            ["UC-13", "Publish a place", "Administrator", "Pin saved and visible to students", "Duplicate identifier, inactive place hidden"],
            ["UC-14", "Broadcast", "Administrator", "Students receive a notice", "Unauthenticated admin call rejected"],
            ["UC-15", "Edit indoor area", "Administrator", "Points and edges saved", "Edge list is explicit, not inferred through walls"],
        ],
    )
    heading(document, "4.8.1  Narrative of the principal use case", 3)
    body(
        document,
        "In UC-04 and UC-08 together, the student asks “where is the library?”. The phone normalises the text, matches Central Library because the name or alias is present, and shows the card. The student taps directions. The campus guide checks the campus outline. Inside it, the router runs Dijkstra from the current node, or from a node the student picks, to the library’s node. The map draws the nodes and shows instructions such as the walk from the Main Gate by the south path. The student can end the route. If the same student had asked from outside the outline, the application would open a walking link to the nearest gate instead of pretending the city network is the campus graph.",
    )
    body(
        document,
        "In UC-05, the student asks “when does the library open?”. This is not treated as a directions request merely because the word library appears. The service retrieves the hour passage. The reply quotes the stored hours. A place card is attached only because that passage is tagged with the library identifier. The student may then choose to open the map. The hours themselves are not a route.",
    )
    heading(document, "4.9  Constraints and assumptions carried into design", 2)
    bullet(document, "Semester values in the demonstration record run from 1 to 4, and sections are A or B, matching the seeded catalogue.")
    bullet(document, "Department codes include BSCS, BSPSY, and BBA.")
    bullet(document, "Free-tier hosting may sleep. The interface must say so.")
    bullet(document, "Floor artwork may be a sketch. The graph remains the authority for the route.")
    bullet(document, "English and Roman Urdu are in scope for place lookup. A full Urdu speech interface is not required for acceptance.")
    heading(document, "4.10  Summary", 2)
    body(
        document,
        "The specification fixes twenty-five functions, twelve qualities, two user classes, and fifteen use cases. The qualities of grounding, key handling, and honest distance estimates are requirements, not optional polish. Chapter 5 describes the method by which those requirements were met.",
    )


def add_chapter_5(document):
    page_break(document)
    heading(document, "Chapter 5  Methodology", 1)
    heading(document, "5.1  Development process", 2)
    body(
        document,
        "The system was built in short milestones that could be shown on a phone before the next one started. Foundations came first: a mobile Firebase project, a reachable campus service, theme tokens, shared widgets, splash and routing, typed API errors, and authentication. The student shell, dashboard, chat, voice, history, notifications, and teacher directory followed. Campus navigation was then added as its own sequence: places, the outdoor graph, place cards in chat, administrator place editing, and indoor floors on the same place identifiers. Each milestone had a visible check. A later milestone was not allowed to break sign-in or chat in order to draw a map.",
    )
    body(
        document,
        "This is an incremental process rather than a single waterfall handoff. Requirements still precede design in this report, because a reader needs that order. In the workshop, a milestone often sharpened a requirement. The indoor start is an example. Early notes considered a continuous indoor position. Walking a corridor with ordinary GPS showed that the fix was not stable enough to be the start of a route. The requirement became a QR code or a chosen node. The report states the requirement as it stands after that evidence, and Chapter 8 does not claim a radio-positioning result that was abandoned.",
    )
    heading(document, "5.2  Tools and technologies", 2)
    table_caption(document, "Table 5.1  Tools and responsibilities")
    add_table(
        document,
        ["Tool", "Role in AICC"],
        [
            ["Flutter and Dart", "Student and administrator applications, tests, and floor drawing"],
            ["Provider", "Session, theme, and the indoor map controller"],
            ["Firebase Authentication", "Email and password sessions"],
            ["Cloud Firestore", "Mobile chat, faculty, activity, and campus records behind the service"],
            ["Firebase Cloud Messaging", "Push notices that open the inbox"],
            ["FastAPI and Uvicorn", "HTTP API, validation, and the admin browser surface"],
            ["Pydantic", "Request and response shapes, including registration checks"],
            ["Groq", "Handbook wording and audio transcription, server side only"],
            ["fastembed", "Passage embeddings for retrieval"],
            ["flutter_map and latlong2", "Outdoor map and geographic points"],
            ["mobile_scanner and qr_flutter", "Reading and showing a start-point code"],
            ["flutter_tts and record", "Spoken replies and captured questions"],
            ["Python unit tests and flutter test", "Routers, intent, places, and widgets"],
        ],
    )
    body(
        document,
        "The language-model vendor can be replaced without replacing the phone. The phone speaks HTTP. The prompt, the handbook, and the key live in the service. That boundary was a methodology choice as much as a security choice. It keeps a future change of model from becoming a mobile release.",
    )
    heading(document, "5.3  Conversation and grounding method", 2)
    body(
        document,
        "Every utterance is normalised: trimmed, lowercased, and collapsed to single spaces. A small ordered classifier then runs. Greetings are answered locally. Requests that mention a challan or a roll slip open the document flow. Faculty wording is routed to teacher search. Personal academic wording that is not a policy question is routed to the signed-in record. If none of those fire, the place matcher runs. It scores the place list and prefers a longer explicit name, so “LGU cafe” beats a shorter fragment. Only after a place miss does the local knowledge list, and then the remote handbook, get the question.",
    )
    body(
        document,
        "Remote answering is retrieval first. Handbook entries are loaded from a file that stores the question in English, Urdu, and Roman Urdu beside one answer. Tokens drop stop-words and expand a small alias list. BM25 scores lexical overlap. An embedding cosine score catches a paraphrase. The best passages are placed in the model context with an instruction to use two to four sentences, to quote numbers exactly, and to admit a miss. The service also computes place identifiers separately, from passage tags and from a short list of food words that map to the cafe. The model’s text is never parsed to discover a coordinate.",
    )
    body(
        document,
        "This order is the method’s main safeguard. A classifier that called the model first would spend latency and money on questions that are lookups, and it would give the model a chance to answer them creatively. Lookups are cheaper, faster, and checkable. Generation is reserved for the residue.",
    )
    heading(document, "5.4  Outdoor routing method", 2)
    body(
        document,
        "The outdoor graph is a set of labelled nodes with coordinates and a set of connections. Only published items are searched. Each connection has an optional length and an optional instruction, and it may be bidirectional. Dijkstra grows a frontier from the start node. The cost of a step is the stored length, or 25 metres when the length is missing. The route remembers whether any step was estimated. Reconstruction walks the predecessor map back from the goal and reverses it. If the goal was never reached, the route is empty and the interface says so rather than drawing a straight line across buildings.",
    )
    body(
        document,
        "The straight line was rejected because it is what a public map already approximates, and it crosses lawns and blocks that are not paths. A visibility graph over raw building polygons was also set aside for the outdoor campus. The administrator-authored walkway is easier to correct after one site visit: disable an edge, add a node, publish again. The algorithm does not infer a shortcut the author did not draw.",
    )
    body(
        document,
        "Off-campus behaviour is a method decision, not a failure. The phone tests the campus outline. Outside it, city walking is delegated. The destination of that handoff is a gate, not an indoor room, because the public map cannot finish the indoor part and should not be asked to.",
    )
    heading(document, "5.5  Indoor routing method", 2)
    body(
        document,
        "An indoor building has an origin in latitude and longitude and a rotation, so local metres can be placed on the earth. Floors hold a footprint, rooms with polygons and doors, and navigation nodes joined by explicit edges. A node may be a corridor junction, a door, a stair, or a lift. A vertical link carries the identifier of the node on the other floor. The router builds one graph across floors. The student path is A* with straight-line distance as the heuristic. The same expansion with a zero heuristic is Dijkstra and is used to check that both agree on the demonstration building.",
    )
    body(
        document,
        "Costs are data. Table 5.2 lists the values the search reads. They are metre-equivalents, not a claim of measured walking time for every student. Time is cost divided by 1.2 metres per second after the path is known. A preference for stairs adds 40 metres to each lift link so the lift stops winning. Turns smaller than 25 degrees are spoken as straight. A simulated position more than 8 metres from the route segment is off the route, which feeds the state in Figure 6.7.",
    )
    table_caption(document, "Table 5.2  Indoor route costs")
    add_table(
        document,
        ["Cost", "Value", "Meaning"],
        [
            ["Stairs", "12 per floor", "Added when a stair link changes level"],
            ["Lift", "8 per floor", "Added when a lift link changes level"],
            ["Walking speed", "1.2 m/s", "Converts cost to a time after search"],
            ["Stair preference", "40 on each lift link", "Makes the lift less attractive"],
            ["Turn ignore", "25 degrees", "Small bends stay one instruction"],
            ["Off route", "8 metres", "Farther than this, the session leaves the path"],
        ],
    )
    body(
        document,
        "Instructions are built from the path after search, not during it. A floor change becomes a stair or lift sentence. A heading change above the ignore threshold becomes a turn. Arrival names the room. The same strings can be shown as a list if the student does not want to watch the line on the floor plan. The method therefore separates search, costing, and language. Each can change without the others.",
    )
    heading(document, "5.6  Data, security, and evaluation method", 2)
    body(
        document,
        "Two Firebase projects separate mobile identity from campus demonstration records. The phone signs in against the mobile project. The service uses a service account to read and write campus records. Students are seeded as a repeatable set so a dashboard demonstration does not depend on a private production extract. Secrets are environment values. The repository does not contain the service-account file or the model key. Admin operations check a credential before broadcast, deletion, or password changes.",
    )
    body(
        document,
        "Evaluation has three layers, described fully in Chapters 7 and 8. Unit tests call the pure functions: place match, intent, outdoor Dijkstra, indoor A* and Dijkstra, coordinate conversion, and graph validation. Service tests check that a handbook plan attaches the cafe when the passage or the food rule says so. A scripted manual list checks the sentences a reviewer will type in a viva, including a refusal and an off-campus handoff. A field log for GPS error exists as a table with blank measurements. The method does not fill that table with hoped-for metres.",
    )
    heading(document, "5.7  Summary", 2)
    body(
        document,
        "The method is incremental delivery, lookup before generation, Dijkstra on an authored outdoor graph, A* on an authored indoor graph, and tests aimed at the pure decisions. Chapter 6 shows how those methods are partitioned into subsystems and how the subsystems interact.",
    )
