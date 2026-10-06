✓ prism-8xz · Show Story and Epic acceptance only on explicit request   [P2 · CLOSED]
Created by: Alexey Samoylov · Type: story
Created: 2026-08-04 · Updated: 2026-08-04

CLOSE REASON

  Acceptance met: full host Story and Epic pre-approve prompts omit           
  unsolicited acceptance, explicit-request and internal readiness behavior are
  preserved, all lifecycle and packaging checks pass                          

DESCRIPTION

  Pre-Authoring Analysis                                                      
                                                                              
  KNOWN: The full host Story Human prompt and Epic Approval prompt currently  
  require complete acceptance output before approval. KNOWN: the operator     
  explicitly requires acceptance criteria to appear only on request on both   
  $prism:story and $prism:epic, including their pre-approve gates. KNOWN:     
  design/task and architecture/roadmap summaries remain sufficient user-facing
  approval context, while Beads acceptance remains an internal readiness      
  input. No unresolved product decision remains.                              
                                                                              
  # Request-only Story and Epic acceptance output — Requirements Document     
                                                                              
  ## 1. Overview                                                              
                                                                              
  The full host Prism Story and Epic lifecycles must keep acceptance criteria 
  in Beads as durable requirements while omitting them from unsolicited user- 
  facing Markdown, including Human and Approval pre-approve prompts. Actors   
  are Prism operators running $prism:story or $prism:epic.                    
                                                                              
  ## 2. Scope                                                                 
                                                                              
  ### In Scope                                                                
                                                                              
  • Full host Story and Epic skill output boundaries and pre-approve          
  references.                                                                 
  • Story and Epic canonical skill trees and their prefixed mirrors.          
  • Story/Epic architecture and user documentation, lifecycle ownership       
  metadata, validators, and forward-contract tests.                           
                                                                              
  ### Out of Scope                                                            
                                                                              
  • Prism Light and Prism Callee lifecycle behavior.                          
  • Authorization labels, decision classification, Apply/Delivery semantics,  
  and acceptance storage.                                                     
  • Files under pack/callee.                                                  
                                                                              
  ## 3. Definitions and Glossary                                              
                                                                              
  • Explicit request: an operator message directly asking to view acceptance  
  criteria.                                                                   
  • Pre-approve prompt: the Story Human or Epic Approval phase output         
  requesting authorization for the current plan.                              
  • Unsolicited output: user-facing acceptance content emitted without an     
  explicit request.                                                           
  • Current item: the Story or Epic targeted by the active lifecycle          
  invocation.                                                                 
                                                                              
  ## 4. Requirements                                                          
                                                                              
  ### Functional Requirements                                                 
                                                                              
  • REQ-OUTPUT-001: Full Story and Epic lifecycles MUST NOT emit a standalone 
  acceptance criteria heading or approval-format acceptance block unless the  
  operator explicitly requests acceptance criteria.                           
  • REQ-OUTPUT-002: REQ-OUTPUT-001 MUST apply to Story Human and Epic Approval
  pre-approve prompts.                                                        
  • REQ-STORY-001: Story pre-approve MUST present Design summary, Task summary,
  and Approval request in that order.                                         
  • REQ-EPIC-001: Epic pre-approve MUST present Architecture summary, Story   
  roadmap, and Approval request in that order.                                
  • REQ-READY-001: Story and Epic gates MUST still require usable acceptance  
  in Beads and return incomplete items to their respective specification phase
  without presenting approval.                                                
  • REQ-REQUEST-001: An explicit criteria request MUST allow complete,        
  untruncated acceptance for the current item only.                           
                                                                              
  ### Non-Functional Requirements                                             
                                                                              
  • REQ-TEST-001: Automated validators and forward-contract tests MUST fail if
  either full host pre-approve contract requires unsolicited acceptance output.
  • REQ-COMPAT-001: Internal and machine-readable acceptance artifacts MUST   
  remain permitted and unchanged.                                             
                                                                              
  ### Constraints                                                             
                                                                              
  • CON-001: pack/callee MUST NOT be modified.                                
  • CON-002: Beads remains the durable lifecycle state store.                 
  • CON-003: human:approved remains the only Apply or Delivery authorization. 
                                                                              
  ## 5. Dependencies                                                          
                                                                              
  • DEP-001: Existing Story/Epic skills, mirrors, architecture docs, lifecycle
  ownership metadata, and contract-test infrastructure.                       
                                                                              
  ## 6. Assumptions                                                           
                                                                              
  None identified; the operator explicitly named both full host surfaces and  
  clarified pre-approve behavior.                                             
                                                                              
  ## 7. Risks                                                                 
                                                                              
   ID       | Likelihood | Impact | Mitigation                                
  ----------|------------|--------|-------------------------------------------
   RISK-001 | Low        | Medium | Preserve acceptance readiness checks whi… 
   RISK-002 | Medium     | Medium | Keep Light and Callee expectations surfa… 
   RISK-003 | Low        | Medium | Preserve complete design/task and archit… 
                                                                              
  ## 8. Revision History                                                      
                                                                              
   Version | Date       | Author | Changes                                    
  ---------|------------|--------|--------------------------------------------
   1.0     | 2026-08-04 | Codex  | Initial Story-only interpretation.         
   1.1     | 2026-08-04 | Codex  | Clarified pre-approve request-only behavi… 
   2.0     | 2026-08-04 | Codex  | Expanded request-only behavior to full St… 



DESIGN

  ## Overview and requirements mapping                                        
                                                                              
  Apply one request-only user-facing acceptance policy to the full host Story 
  and Epic lifecycles (REQ-OUTPUT-001, REQ-OUTPUT-002, REQ-REQUEST-001).      
  Preserve Beads acceptance readiness and authorization state transitions     
  (REQ-READY-001, REQ-COMPAT-001). Keep non-acceptance approval context       
  ordered per surface (REQ-STORY-001, REQ-EPIC-001).                          
                                                                              
  ## Explorer evidence and current behavior                                   
                                                                              
  • plugins/prism/skills/story/SKILL.md has an output boundary but explicitly 
  exempts the informed Human request;                                         
  plugins/prism/skills/story/references/human.md mandates Acceptance criteria 
  before Design and Task summaries.                                           
  • plugins/prism/skills/epic/SKILL.md lacks an output boundary;              
  plugins/prism/skills/epic/references/approval.md mandates Acceptance        
  criteria before Architecture and Roadmap summaries.                         
  • plugins/prism/prefixed-skills/prism-story and prism-epic are normalized   
  mirrors checked by scripts/validate-lifecycle-ownership.sh.                 
  • docs/architecture-story-lifecycle.md, docs/architecture-epic-lifecycle.md,
  README.md, and docs/lifecycle-ownership.json describe acceptance-first full 
  host approval.                                                              
  • scripts/validate-lifecycle-ownership.sh and scripts/test-lifecycle-       
  forward-contracts.sh assert acceptance-first Story and Epic order.          
  scripts/test-callee-lifecycle-forward-contracts.sh separately asserts the   
  unchanged direct Callee pack contract and also checks host output boundaries.
  • Light and Callee contracts independently retain acceptance-first prompts; 
  their files and direct-pack checks can remain unchanged.                    
                                                                              
  ## Proposed architecture and data flow                                      
                                                                              
  Current-item Beads acceptance -> readiness validation -> internal pass/fail.
                                                                              
  Failure path: clear approval and return Story to Specify or Epic to Frame   
  without presenting an approval request.                                     
                                                                              
  Ready Story path: render Design summary -> Task summary -> Approval request.
                                                                              
  Ready Epic path: render Architecture summary -> Story roadmap -> Approval   
  request.                                                                    
                                                                              
  Explicit-request path: the main surface output boundary permits complete    
  untruncated acceptance for the current item only.                           
                                                                              
  No-request path: the main surface output boundary prohibits any standalone  
  acceptance heading or unsolicited approval-format acceptance block,         
  including pre-approve.                                                      
                                                                              
  ## Components and interfaces                                                
                                                                              
  • Canonical Story and Epic SKILL.md files own the global user-facing output 
  boundary. Both use identical request-only language and preserve             
  internal/machine-readable artifacts (REQ-OUTPUT-001, REQ-OUTPUT-002, REQ-   
  REQUEST-001, REQ-COMPAT-001).                                               
  • Story references/human.md and Epic references/approval.md own readiness   
  and the three-section surface-specific prompt order (REQ-STORY-001, REQ-    
  EPIC-001, REQ-READY-001).                                                   
  • Prefixed Story and Epic trees mirror canonical behavior for flat          
  invocations.                                                                
  • docs/lifecycle-ownership.json records full-host approval order and        
  explicit-request acceptance scope under host-specific keys so unchanged     
  Light/Callee behavior is not misrepresented. Increment the ownership schema 
  version because the approval metadata shape changes (REQ-TEST-001).         
  • scripts/validate-lifecycle-ownership.sh validates host Story/Epic absence 
  of unsolicited acceptance separately from acceptance-first Light/Callee     
  contracts. Forward tests consume the host-specific metadata and keep direct 
  Callee checks unchanged (REQ-TEST-001).                                     
  • README and architecture docs describe the observable full-host behavior.  
                                                                              
  ## Decisions and tradeoffs                                                  
                                                                              
  Decision: remove only user-facing pre-approve acceptance, not readiness     
  validation. This satisfies request-only output without weakening gates.     
  Reject heading-only suppression because unlabeled acceptance content remains
  unsolicited. Reject changes to Light/Callee and pack/callee because the     
  operator identified only the full host Story/Epic skills and the active     
  Story contract forbids pack changes.                                        
                                                                              
  Decision: make ownership metadata surface-specific rather than globally     
  redefining every Story/Epic approval surface. This adds a small schema      
  change but prevents accidental semantic drift in Light/Callee checks. The   
  change is reversible and requires no Beads migration.                       
                                                                              
  ## State, errors, trust, and compatibility                                  
                                                                              
  All phase labels, human:approved handling, classification, child ownership, 
  and close-or-bounce behavior remain unchanged. Missing acceptance still     
  fails closed. Explicit operator intent is the only authority for both       
  acceptance disclosure and implementation authorization; these are           
  independent decisions. No API, storage, security boundary, or operational   
  migration changes.                                                          
                                                                              
  ## Verification                                                             
                                                                              
  • Validate canonical/prefixed Story and Epic mirror equality and integrity  
  digests.                                                                    
  • Assert host prompt markers are exactly the three non-acceptance sections  
  in order and that host references do not contain the acceptance heading.    
  • Assert both host main skills prohibit pre-approve exceptions while        
  allowing explicit requests and internal artifacts.                          
  • Preserve Light/Callee acceptance-first assertions and direct Callee pack  
  immutability.                                                               
  • Run lifecycle ownership validation, drift detection, host forward tests,  
  Callee forward-contract tests, plugin packaging validation, and inspect the 
  diff for pack/callee changes.                                               
                                                                              
  ## Risks and open questions                                                 
                                                                              
  Shared validators can accidentally conflate host and Callee surfaces;       
  explicit per-surface assertion sets mitigate this. Digest metadata can      
  drift; lifecycle integrity validation detects it. No blocking unknowns      
  remain.                                                                     



NOTES

  Human refinement at pre-approve: apply the same request-only acceptance-    
  criteria output rule to the full prism:epic skill, including its pre-approve
  Approval phase. Revise requirements, design, task coverage, docs, metadata, 
  and validators before requesting approval again.                            



ACCEPTANCE CRITERIA

  REQ-OUTPUT-001                                                              
                                                                              
  • Given normal full Story or Epic output and no explicit criteria request,  
  when output is rendered, then it contains neither a standalone acceptance   
  criteria heading nor an approval-format acceptance block.                   
                                                                              
  REQ-OUTPUT-002                                                              
                                                                              
  • Given a ready Story Human gate or Epic Approval gate and no explicit      
  criteria request, when its pre-approve prompt is rendered, then acceptance  
  criteria are omitted.                                                       
                                                                              
  REQ-STORY-001                                                               
                                                                              
  • Given a ready Story at Human, when pre-approve is rendered, then it       
  contains Design summary, Task summary, and Approval request in that order.  
                                                                              
  REQ-EPIC-001                                                                
                                                                              
  • Given a ready Epic at Approval, when pre-approve is rendered, then it     
  contains Architecture summary, Story roadmap, and Approval request in that  
  order.                                                                      
                                                                              
  REQ-READY-001                                                               
                                                                              
  • Given missing or unusable current-item acceptance, when the gate runs,    
  then Story returns to phase:story:specify or Epic returns to                
  phase:epic:frame, approval is cleared, and no approval request is presented.
                                                                              
  REQ-REQUEST-001                                                             
                                                                              
  • Given an explicit operator request for acceptance criteria, when the      
  lifecycle responds, then it may show complete untruncated acceptance for the
  current item only.                                                          
                                                                              
  REQ-TEST-001                                                                
                                                                              
  • Contract validation fails if either full host Story Human or Epic Approval
  reference declares acceptance as an unsolicited prompt section or either    
  main skill declares a pre-approve exception.                                
                                                                              
  REQ-COMPAT-001                                                              
                                                                              
  • Requirements documents, Beads acceptance fields, and machine-readable     
  acceptance sections remain permitted.                                       



LABELS: human:approved, phase:story:verify, prism

CHILDREN
  ↳ ✓ prism-8xz.1: Make full Story and Epic pre-approve output request-only P2

