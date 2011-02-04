class DomainMessage:
    property Expression as Expression
    property Handler as ReferenceExpression
    property Method as Method

def CountMethodInvocations(root as Expression) as int:
    match root:
        case MethodInvocationExpression(Target: target):
            return CountMethodInvocations(target) + 1

        case MemberReferenceExpression(Target: target, Name: name):
            return CountMethodInvocations(target)

        case ReferenceExpression(Name: name):
            return 0

def MakeName(root as Expression) as string:
    match root:
        case MethodInvocationExpression(Target: target):
            return "${MakeName(target)}{${CountMethodInvocations(target)}}"

        case MemberReferenceExpression(Target: target, Name: name):
            return "${MakeName(target)}.${name}"

        case ReferenceExpression(Name: name):
            return name

def MakeParameters(root as Expression) as List[of ParameterDeclaration]:
    match root:
        case MethodInvocationExpression(Target: target, Arguments: arguments):
            parameters = List[of ParameterDeclaration]()
            for argument in arguments:
                match argument:
                    case [| $(ReferenceExpression(Name: name)) as $type |]:
                        parameter = ParameterDeclaration(Name: name, Type: type)
                        parameters.Add(parameter)
            targetParameters = MakeParameters(target)
            return targetParameters.Extend(parameters)

        otherwise:
            return List[of ParameterDeclaration]()

macro domain:
    case [| domain $(MethodInvocationExpression(Target: ReferenceExpression(Name: name))) |]:
        domainName = MakeDomainType(name)
        yield [| Pantheon.Universe.Current.Domains.Add($(ReferenceExpression(domainName))()) |]

    case [| domain $(ReferenceExpression(Name: name)) |]:
        domainName = MakeDomainType(name)
        klass = [|
            class $(domainName) (Pantheon.Domain):
                $(domain.Body)
        |]
        konstructor = klass.GetConstructor(0)
        for message as DomainMessage in domain.Get("messages"):
            #konstructor.Body.Statements.Add(Statement.Lift([| MessageMethods.Add($(MessageExpression(message.Expression)).Name, $(message.Handler)) |]))
            klass.Members.Add(message.Method)
        yield klass

    case [| domain $(UnaryExpression(Operator: operat0r, Operand: MethodInvocationExpression())) |]:
        match operat0r:
            case UnaryOperatorType.OnesComplement:
                pass

    otherwise:
        for arg in domain.Arguments:
            print arg.GetType()

        macro message:
            case [| message $(expression = ReferenceExpression(Name: name)) |]:
                messageName = MakeMessageType(name)
                method = [|
                    def $(messageName)():
                        $(message.Body)
                |]
                domainMessage = DomainMessage(Expression: expression, Handler: ReferenceExpression(messageName),
                    Method: method)
                domain.Add("messages", domainMessage)

            case [| message $(expression2 = MethodInvocationExpression()) |]:
                name = NameFromSignature(expression2)
                messageName = MakeMessageType(name)
                method = [|
                    def $(messageName)():
                        $(message.Body)
                |]
                domainMessage = DomainMessage(Expression: expression2, Handler: ReferenceExpression(messageName),
                    Method: method)
                domain.Add("messages", domainMessage)
                /*methodName = MakeName(signature)
                #targetName = NameFromSignature(signature)
                #messageName = MakeMessageType(targetName)
                messageName = "${methodName}Message"
                method = [|
                    def $(messageName)():
                        $(message.Body)
                |]
                method.Parameters.Extend(MakeParameters(signature))
                domainMessage = DomainMessage(MessageDefinition: messageName, Handler: method)
                domain.Add("messages", domainMessage)*/

            otherwise:
                raise "wat"