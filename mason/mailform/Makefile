DOCROOT=/usr/local/htdocs

clean:
	rm *~

install-once:
	cp mailform.mc $(DOCROOT)

dist:
	cp -r /usr/local/james/htdocs/mailform/*.mc /usr/local/james/htdocs/mailform/templates/ .
	(cd .. ; rm DRRHO-mailform-* ; ln -s mailform DRRHO-mailform-`grep Version mailform/DATA | awk '{print $$2}'` ; tar zcvf mailform/DRRHO-mailform-`grep Version mailform/DATA | awk '{print $$2}'`.tgz --dereference --exclude=*.tgz --exclude=*~ DRRHO-mailform-`grep Version mailform/DATA | awk '{print $$2}'` ) 
